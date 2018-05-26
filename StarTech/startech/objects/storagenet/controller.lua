--
require "/lib/stardust/network.lua"
require "/lib/stardust/itemutil.lua"

-- just dropping this here for now
function ripairs(t)
  local function ripairs_it(t,i)
    i=i-1
    local v=t[i]
    if v==nil then return v end
    return i,v
  end
  return ripairs_it, t, #t+1
end

controller = {}

local itemCache = {}
local itemFindCache = {}
local itemUpdateId = 0
local function checkUpdateItems()
  if self.timerPollStorage > 0 then return nil end -- rate limit
  self.timerPollStorage = math.floor(60*2.5)
  itemUpdateId = itemUpdateId + 1
  
  -- okay, here it goes
  local function itemcpy(item)
    return {
      name = item.name,
      count = item.count,
      parameters = item.parameters
    }
  end
  
  local dict = {}
  local function stackIn(item)
    if not item.count then item.count = 1 end -- not sure how this would happen, but just in case
    if not dict[item.name] then
      dict[item.name] = {}
    end
    local list = dict[item.name]
    if not item.parameters then
      if not list[0] then list[0] = itemcpy(item) return nil end
      list[0].count = list[0].count + item.count
    else
      for i = 1, #list do
        if itemutil.canStack(item, list[i]) then
          list[i].count = list[i].count + item.count
          return nil
        end
      end
      list[#list+1] = itemcpy(item)
    end
  end
  
  for k,sp in pairs(controller.poolStorage) do
    --sb.logInfo("polling storage: " .. st)
    local noerr, items = pcall(sp.getItemList, sp)
    if noerr and items then
      for k,item in pairs(items) do stackIn(item) end -- NOT IPAIRS YOU DOLT
    end
  end
  
  local i = 1
  itemCache = {}
  for k,v in pairs(dict) do
    for k,v in pairs(v) do
      itemCache[i] = v
      i = i + 1
    end
  end
  itemFindCache = dict -- might as well save this for quick polling
end

local function sortStoragePool(item)
  local pcache = {}
  local function gp(s)
    local p = pcache[s]
    if not p then
      p = zpcall(s.getPriority, s, item)
      if not p then p = 0 end
      pcache[s] = p
    end
    return p
  end
  table.sort(controller.poolStorageSortable, function(s1, s2)
    if not s1 then return false end
    if not s2 then return true end
    return gp(s1) > gp(s2)
  end)
end

local function sortStoragePoolMain(item)
  local pcache = {}
  local function gp(s)
    local p = pcache[s]
    if not p then
      p = zpcall(s.getPriority, s, item)
      if not p then p = 0 end
      pcache[s] = p
    end
    return p
  end
  table.sort(controller.poolStorage, function(s1, s2)
    if not s1 then return false end
    if not s2 then return true end
    return gp(s1) > gp(s2)
  end)
end

function controller:listItems()
  checkUpdateItems()
  return itemCache, itemUpdateId
end

function controller:findItem(item)
  checkUpdateItems()
  
  local fc = itemFindCache[item.name]
  if fc then
    for i = 0, #fc do
      if itemutil.canStack(item, fc[i]) then return fc[i] end
    end
  end
  
  return nil
end

function controller:tryTakeItem(itemReq)
  local count = 0
  for i, sp in ripairs(controller.poolStorage) do -- ripairs for highest-to-lowest-priority
    local take = zpcall(sp.tryTakeItem, sp, itemReq)
    if take then
      count = count + take.count
      
      if itemReq.count <= 0 then break end
    end
  end
  if count > 0 then setStorageDirty() end
  return {
    name = itemReq.name,
    count = count,
    parameters = itemReq.parameters
  }
end

function controller:tryPutItem(item)
  local startCount = item.count
  sortStoragePool(item)
  for i, sp in ipairs(controller.poolStorageSortable) do
    zpcall(sp.tryPutItem, sp, item)
    if item.count <= 0 then break end
  end
  if item.count ~= startCount then setStorageDirty() end
end


-- controller needs to:
-- list items
-- handle item routing and requesting similar to world.container*
-- keep itself updated on a variable tick system?

-- storage interface:
-- getPriority() -- returns a (usually integer) priority value
-- getItemList() -- exactly how world.containerItems() returns, I guess
-- tryTakeItem(descriptor)
-- tryPutItem(descriptor)


function init()
  controller.id = entity.id()
  
  self.timerPollNetwork = 0
  self.timerPollStorage = 0
  
  object.setInteractive(false) -- there we go, container-safety without weird blank container panes
end

function setStorageDirty() self.timerPollStorage = 0 end

function updateNetwork()
  if controller.pool then
    -- first, "unhook" anything in the old pool; anything still connected will be rehooked
    for i = 1, #(controller.pool) do
      interop.safeCall(controller.pool[i], "shared._var", "controller", nil, true) -- nil,true to delete
    end
  end
  
  -- refresh master pool
  controller.pool = network.getPool(nil, "storageNet")
  -- and hook back up
  for i = 1, #(controller.pool) do
    world.callScriptedEntity(controller.pool[i], "shared._var", "controller", controller)
    world.callScriptedEntity(controller.pool[i], "onStorageNetUpdate") -- give it a ping
  end
  local sp = controller.pool.tagged("storageNet.storage")
  
  controller.poolStorage, controller.poolStorageSortable = {}, {}
  local i = 1
  for k,v in ipairs(sp) do
    local driver = interop.getShared(v).storageProvider
    if driver then -- apparently it can derp out like that
      if driver._array then -- object provides multiple distinct storage elements (implement as metatable to keep iteration from hitting)
        for k,subdriver in pairs(driver) do -- probably don't want ipairs; allow holes for 
          controller.poolStorage[i] = subdriver
          controller.poolStorageSortable[i] = subdriver
          i = i + 1
        end
      else -- just add the one
        controller.poolStorage[i] = driver
        controller.poolStorageSortable[i] = driver
        i = i + 1 -- VERY IMPORTANT!
      end
    end
  end
  sortStoragePoolMain()
end

function update()
  if (not controller.pool) or self.timerPollNetwork <= 0 then
    updateNetwork()
    self.timerPollNetwork = 60*5 -- 5sec
  end
  
  self.timerPollNetwork = self.timerPollNetwork - 1
  if self.timerPollStorage > 0 then self.timerPollStorage = self.timerPollStorage - 1 end
end





function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
