--
require "/scripts/util.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/tasks.lua"
require "/lib/stardust/interop.lua"
--require "/lib/stardust/itemutil.lua"

local nullFunc = function() end
local returnZero = function() return 0 end
local nullTable = { }

local processes = taskQueue()

local devices = { } -- map<objId, { handle, storage = map<storageProvider, true> }>
local storageByPriority

local itemCache = { }
local displayCache
local displayCacheId

local cacheProto = { }
local cacheMeta = { __index = cacheProto }
local subcacheProto = { }
local subcacheMeta = { __index = subcacheProto }

function cacheProto:iterate()
  return coroutine.wrap(function()
    coroutine.yield(self.normal)
    for e in pairs(self.variants) do coroutine.yield(e) end
  end)
end
function cacheProto:match(itm)
  if not itm then return nil end
  for sc in self:iterate() do
    if root.itemDescriptorsMatch(itm, sc.descriptor, true) then return sc end
  end
  return nil -- explicit
end

function cacheProto:recalculate()
  for v in self:iterate() do v:recalculate() end
end
function subcacheProto:recalculate()
  local c = 0
  for s, cc in pairs(self.storage) do
    c = c + cc
  end
  self.descriptor.count = c
  if c <= 0 then -- reap
    self.entry.variants[self] = nil
  end
end


local function cacheFor(itm, create)
  local isDesc = type(itm) == "table"
  local id = isDesc and itm.name or itm
  local mc = itemCache[id]
  if not mc then
    if not create then return nil end
    mc = setmetatable({
      id = id,
      normal = {
        descriptor = { name = id, count = 0, parameters = nullTable },
        storage = { },
      },
      variants = { },
    }, cacheMeta)
    mc.entry = mc
    mc.normal.entry = mc
    itemCache[id] = mc
  end
  if not isDesc then return mc end
  local sc = mc:match(itm)
  if not sc then
    if not create then return nil end
    sc = setmetatable({
      entry = mc,
      descriptor = { name = id, count = 0, parameters = itm.parameters },
      storage = { },
    }, subcacheMeta)
    mc.variants[sc] = true
  end
  return sc
end

local function priorityList()
  if storageByPriority then return storageByPriority end
  storageByPriority = { }
  for id, dev in pairs(devices) do
    for sp in pairs(dev.storage) do storageByPriority[sp] = sp end
  end
  table.sort(storageByPriority, function(a, b) return b.priority < a.priority end)
  return storageByPriority
end

local storageProto = { }
local storageMeta = { __index = storageProto }
storageProto.priority = 0

storageProto.tryTakeItem = returnZero
storageProto.tryPutItem = returnZero

storageProto.onConnect = nullFunc
storageProto.onDisconnect = nullFunc

function storageProto:updateItemCounts(lst)
  if self.dead or not lst then return end
  displayCache = nil -- invalidate old terminal cache
  if lst.name then lst = {lst} end -- allow descriptor input
  for _, itm in pairs(lst) do
    local sc = cacheFor(itm, itm.count > 0)
    if sc then
      local prev = sc.storage[self] or 0
      sc.storage[self] = itm.count > 0 and itm.count or nil -- set or clear contributing count
      self.cache[sc] = itm.count > 0 or nil -- set whether this is contributing
      local d = itm.count - prev
      sc.descriptor.count = sc.descriptor.count + d
      if sc.descriptor.count <= 0 then -- reap
        sc.entry.variants[sc] = nil
      end
    end
  end
end

function storageProto:clearItemCounts()
  if self.dead then return end
  local lst = { }
  for sc in pairs(self.cache) do -- assemble list of zero-counts
    table.insert(lst, { name = sc.descriptor.name, parameters = sc.descriptor.parameters, count = 0 })
  end
  self:updateItemCounts(lst)
end

function storageProto:setPriority(p)
  self.priority = p
  storageByPriority = nil -- invalidate old
end

function storageProto:disconnect()
  self:clearItemCounts()
  local dev = devices[self.handle.id]
  dev.storage[self] = nil -- remove from listing
  self:onDisconnect()
  self.dead = true
  storageByPriority = nil -- invalidate
end

-- -- --

local handleProto = { }
local handleMeta = { __index = handleProto }
handleProto.connected = true -- indicator
local transactionProto = { }
local transactionMeta = { __index = transactionProto }
local transactionDef = { } -- functions
local transactionQueue = { }

-- event stubs
handleProto.onConnect = nullFunc
handleProto.onDisconnect = nullFunc

function handleProto:disconnect()
  local dev = devices[self.id]
  if dev then
    for sp in pairs(dev.storage) do
      sp:disconnect()
    end
    
    devices[self.id] = nil
  end
  self:onDisconnect()
  setmetatable(self, nil) -- deactivate
end

function handleProto:getDisplayCache()
  if not displayCache then -- assemble
    displayCache = { }
    displayCacheId = sb.makeUuid()
    for id, e in pairs(itemCache) do
      for v in e:iterate() do
        if v.descriptor.count > 0 then table.insert(displayCache, v.descriptor) end
      end
    end
  end
  return displayCache, displayCacheId
end

function handleProto:registerStorage(proto, ...)
  if not proto.__meta then proto.__meta = { __index = proto } end -- stash this
  setmetatable(proto, storageMeta)
  local dev = devices[self.id]
  local sp = setmetatable({
    handle = self,
    connected = true,
    cache = { }, -- only need this as a set of each individual variant affected
  }, proto.__meta)
  dev.storage[sp] = true
  sp:onConnect(...)
  storageByPriority = nil -- invalidate
  return sp
end

function handleProto:startTransaction(arg)
  if not arg or not arg[1] then return nil end
  local func = transactionDef[arg[1]]
  if not func then return nil end
  local tr = setmetatable({ args = arg, handle = self }, transactionMeta)
  
  tr.crt = coroutine.create(func)
  tr:run() -- first tick
  
  if not tr.dead then transactionQueue[tr] = true end
  
  return tr
end
handleProto.transaction = handleProto.startTransaction -- alias

function transactionProto:run()
  if self.dead then return self end
  local s, err = coroutine.resume(self.crt, self)
  if not s then
    sb.logError("Transaction error: " .. err)
    self:fail "error"
  elseif coroutine.status(self.crt) == "dead" then -- finished naturally
    self.dead = true
    self:onFinish()
  end
  return self -- chainable
end

function transactionProto:runUntilFinish(sync) while not self.dead do self:run() end return self end
function transactionProto:waitFor() while not self.dead do coroutine.yield() end end

transactionProto.onFinish = nullFunc
transactionProto.onFail = nullFunc
function transactionProto:fail(ftype)
  self.dead = true
  self.failType = ftype
  self:onFail()
end

-- -- --

function transactionDef:request()
  if not self.args.item then return self:fail "invalid" end
  local itm = self.args.item
  local sc = cacheFor(itm)
  if not sc then return self:fail "notFound" end
  if self.args.exact and sc.descriptor.count < itm.count then return self:fail "notFound" end -- exactitude not hard-guaranteed
  itm.parameters = sc.descriptor.parameters -- deduplicate
  
  local req = { name = itm.name, parameters = itm.parameters } -- dummy request item
  local needed = itm.count
  local count = 0
  local sl = util.mergeTable({ }, sc.storage) -- copy so iteration doesn't get wonked when counts get updated
  for sp in pairs(sl) do
    req.count = needed - count
    count = count + (sp:tryTakeItem(req) or 0)
    if count >= needed then break end
  end
  
  -- might as well reuse request for result
  req.count = count
  self.result = req
end

do -- encapsulate
  local function insertIteration(sc)
    return coroutine.wrap(function()
      if sc then -- 
        for sp in pairs(sc.storage) do coroutine.yield(sp) end
      end
      for _, sp in pairs(priorityList()) do coroutine.yield(sp) end
    end)
  end
  function transactionDef:insert()
    if not self.args.item then return self:fail "invalid" end
    local itm = self.args.item
    
    local req = { name = itm.name, count = itm.count, parameters = itm.parameters } -- operate on a copy
    for sp in insertIteration(cacheFor(itm)) do
      req.count = req.count - (sp:tryPutItem(req) or 0)
      if req.count <= 0 then return end -- no leftovers
    end
    self.result = req -- return leftovers
  end
end

----------------------------------------------------------------

function init()
  
  object.setInteractive(false) -- disable container interface
  
  -- set all outputs positive for chunkloading purposes
  for i=1, object.outputNodeCount() do object.setOutputNodeLevel(i-1, true) end
  
  -- TEMP TESTING
  --cacheFor({name = "ironbar", parameters = { }}, true).descriptor.count = 3
  
  
end

function uninit()
  while true do -- break all connections
    local id, dev = pairs(devices)(devices)
    if not dev then break end
    dev.handle:disconnect()
  end
end

function update(dt)
  processes:run()
end

processes:spawn("networkManager", function()
  --
  local pool
  
  while true do
    local old = pool
    pool = network.getPool(nil, "startech:storagenet.device")
    local delta = pool:delta(old)
    
    for id in pairs(delta.removed) do
      local dev = devices[id]
      if dev then dev.handle:disconnect() end
    end
    
    for id in pairs(delta.added) do
      local env = interop.hack(id)
      if env then
        if not env.storagenet then env.storagenet = { } end
        local handle = env.storagenet
        setmetatable(handle, handleMeta)
        handle.id = id
        handle.env = env
        
        local dev = { handle = handle, storage = { } }
        devices[id] = dev
        
        if not env["$$storagenet.hooked"] then
          env["$$storagenet.hooked"] = true
          local _uninit = env.uninit or nullFunc
          function env.uninit(...)
            if env.storagenet.active then env.storagenet:disconnect() end -- immediate discard
            _uninit(...)
          end
        end
        
        handle:onConnect()
      end
    end
    
    
    util.wait(5)
  end
end)

processes:spawn("transactions", function()
  while true do
    -- if we implement transaction process limits later, we can change this to "finish our set first"
    local cq = transactionQueue
    transactionQueue = { }
    
    for tr in pairs(cq) do
      tr:run()
      if not tr.dead then transactionQueue[tr] = true end
    end
    
    coroutine.yield()
  end
end)
