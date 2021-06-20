--
require "/scripts/util.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/tasks.lua"
require "/lib/stardust/interop.lua"
--require "/lib/stardust/itemutil.lua"

local nullFunc = function() end
local nullTable = { }

local processes = taskQueue()

local devices = { }
--[[ map<objId, device>
  device = {
    handle
    storage = map<storageProvider, true>
  }
]]

local itemCache = { }
--[[ map<itemname, cache>
  cache = {
    types = {
      [1] = {
        descriptor = <item descriptor>
        storage = map<provider, count>
      }
      ...
    }
  }
]]

local cacheProto = { }
local cacheMeta = { __index = cacheProto }

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
    sc = {
      entry = mc,
      descriptor = { name = id, count = 0, parameters = itm.parameters },
      storage = { },
    }
    mc.variants[sc] = true
  end
  return sc
end

local storageProto = { }
local storageMeta = { __index = storageProto }

function storageProto:getPriority() return 0 end
storageProto.tryTakeItem = nullFunc
storageProto.tryPutItem = nullFunc

storageProto.onConnect = nullFunc
storageProto.onDisconnect = nullFunc

function storageProto:updateItemCounts(lst)
  for _, itm in pairs(lst) do
    
  end
end

function storageProto:disconnect()
  
end

-- -- --

local handleProto = { }
local handleMeta = { __index = handleProto }
handleProto.connected = true -- indicator

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

function handleProto:registerStorage(proto, ...)
  if not proto.__meta then proto.__meta = { __index = proto } end -- stash this
  setmetatable(proto, storageMeta)
  local dev = devices[self.id]
  local sp = setmetatable({
    handle = self,
    connected = true,
    cache = { }, -- mirror main cache layout?? actually, just plonk the main cache entries in here? maybe only subentries
  }, proto.__meta)
  dev.storage[sp] = true
  sp:onConnect(...)
  return sp
end



----------------------------------------------------------------

function init()
  
  object.setInteractive(false) -- disable container interface
  
  -- set all outputs positive for chunkloading purposes
  for i=1, object.outputNodeCount() do object.setOutputNodeLevel(i-1, true) end
  
  -- TEMP TESTING
  cacheFor({name = "lol", parameters = { chicken = "yes" }}, true)
  
  function b(itm)
    local str = cacheFor(itm) and "yes" or "no"
    sb.logInfo("cache says " .. str)
  end
  
  b { name = "lol", parameters = { } }
  b { name = "lol", parameters = { fumble = 3 } }
  b { name = "lol", parameters = { chicken = "yes" } }
  
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
        
        handle:onConnect()
      end
    end
    
    
    util.wait(5)
  end
end)
