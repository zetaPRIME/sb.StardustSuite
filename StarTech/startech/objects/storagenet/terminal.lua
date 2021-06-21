require "/scripts/vec2.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/tasks.lua"

storagenet = { }

local provider = { }

function storagenet:onConnect()
  object.say "connected!"
  --prov = storagenet:registerStorage(provider)
end

function storagenet:onDisconnect()
  object.say "disconnected."
end

function provider:onConnect()
  self:updateItemCounts(world.containerItems(entity.id()))
end

local svc = { }
local openPlayers = { }

function dbg(txt)
  sb.logInfo(txt)
  object.say(txt)
end

function svc.listItems()
  if not storagenet.connected then return { } end
  
  local cache = storagenet:getDisplayCache()
  return cache
end

function svc.updateItems(msg, isLocal, updateId)
  if not storagenet.connected then return { } end
  
  local cache, id = storagenet:getDisplayCache()
  if id ~= updateId then return cache end
end

function svc.request(msg, isLocal, item, player)
  if not storagenet.connected then return end
  local tr = storagenet:transaction { "request", item = item }
  
  local result = tr:runUntilFinish().result
  if result and result.count > 0 then
    world.sendEntityMessage(player, "playerext:giveItemToCursor", result, true)
  end
end

-- -- --

function init()
  for k, v in pairs(svc) do message.setHandler(k, v) end
end

_ccdis = false
function containerCallback(...)
  if _ccdis then return end
  
  local ejectPos = entity.position()
  for pid in pairs(openPlayers) do -- drop it on an interacting player if any exist
    ejectPos = world.entityPosition(pid) or ejectPos
    break
  end
  
  if not storagenet.connected then -- just spit items out
    _ccdis = true
    for i, itm in pairs(world.containerTakeAll(entity.id())) do world.spawnItem(itm, ejectPos) end
    _ccdis = false
    return
  end
  _ccdis = true
  
  local itemsInserted = world.containerTakeAll(entity.id())
  for i, itm in pairs(itemsInserted) do
    local tr = storagenet:transaction { "insert", item = itm }
    local result = tr:runUntilFinish().result
    if result and result.count > 0 then 
      world.spawnItem(itm, ejectPos) -- pop it out if it doesn't fit the network anymore
    end
  end
  
  _ccdis = false
end
