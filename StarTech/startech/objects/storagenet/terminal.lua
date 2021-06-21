require "/scripts/vec2.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/tasks.lua"

storagenet = { }
local prov

local provider = { }

function storagenet:onConnect()
  object.say "connected!"
  prov = storagenet:registerStorage(provider)
end

function storagenet:onDisconnect()
  object.say "disconnected."
end

function provider:onConnect()
  self:updateItemCounts(world.containerItems(entity.id()))
end

local svc = { }

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

function containerCallback()
  if not storagenet.connected then return end
  prov:clearItemCounts()
  prov:updateItemCounts(world.containerItems(entity.id()))
end
