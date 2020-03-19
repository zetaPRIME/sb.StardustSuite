require "/scripts/vec2.lua"

require "/lib/stardust/network.lua"
--require "/lib/stardust/sync.lua"

openPlayers = {}
inUse = false
playerTimeout = -1

function init()
  object.setInteractive(true)
  
  lastUsedBy = -1
  
  message.setHandler("listItems", sendItemList)
  message.setHandler("updateItems", updateItemList)
  message.setHandler("request", fulfillRequest)
  message.setHandler("ping", function(msg, isLocal, pid) lastUsedBy = pid end)
  
  message.setHandler("playerOpen", playerOpen)
  message.setHandler("playerClose", playerClose)
  message.setHandler("playerHeartbeat", playerHeartbeat)
end

function playerOpen(msg, isLocal, pid)
  openPlayers[pid] = true
  lastUsedBy = pid
  playerTimeout = math.floor(60 * 0.5) -- give some extra time to account for potential client lag on loading
end

function playerClose(msg, isLocal, pid)
  openPlayers[pid] = nil
  --object.say("playerClose")
end

function playerHeartbeat(msg, isLocal, pid)
  playerTimeout = math.max(playerTimeout, math.floor(60 * 0.25))
  openPlayers[pid] = true -- might as well pick back up
end

function update(dt)
  playerTimeout = playerTimeout - 1
  if playerTimeout == 0 then openPlayers = {} end -- assume last player has lost dialog if no update recieved
  
  local isOpen = false
  local pos = entity.position()
  for pid in pairs(openPlayers) do
    isOpen = true
    local ppos = world.entityPosition(pid)
    if not ppos or world.magnitude(pos, ppos) > 8 then openPlayers[pid] = nil end
  end
  
  if isOpen ~= inUse then
    object.setAnimationParameter("active", isOpen)
  end
  inUse = isOpen
end

function dump(o, ind)
  if not ind then ind = 2 end
  local pfx, epfx = "", ""
  for i=1,ind do pfx = pfx .. " " end
  for i=3,ind do epfx = epfx .. " " end
  if type(o) == 'table' then
    local s = '{\n'
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. pfx .. '['..k..'] = ' .. dump(v, ind+2) .. ',\n'
    end
    return s .. epfx .. '}'
  else
    return tostring(o)
  end
end

_ccdis = false
function containerCallback(...)
  if _ccdis then return nil end
  
  local ejectPos = entity.position()
  for pid in pairs(openPlayers) do -- drop it on an interacting player if any exist
    ejectPos = world.entityPosition(pid) or ejectPos
    break
  end
  
  if not shared.controller then -- just spit items out
    _ccdis = true
    for i, itm in pairs(world.containerTakeAll(entity.id())) do world.spawnItem(itm, ejectPos) end
    _ccdis = false
    return nil
  end
  _ccdis = true
  
  local itemsInserted = world.containerTakeAll(entity.id())
  for i, itm in pairs(itemsInserted) do
    shared.controller:tryPutItem(itm)
    if itm.count > 0 then 
      --world.containerAddItems(entity.id(), itm)
      world.spawnItem(itm, ejectPos) -- pop it out if it doesn't fit the network anymore
    end
  end
  
  _ccdis = false
end

function sendItemList()
  if not shared.controller then return {} end
  return shared.controller:listItems()
end

function updateItemList(msg, isLocal, updateId)
  if not shared.controller then return {} end
  local items, uid = shared.controller:listItems()
  if items and uid ~= updateId then return items, uid end
end

function fulfillRequest(msg, isLocal, item, player)
  if lolDebug then
    local itmDump = dump(item)
    object.say(itmDump)
    sb.logInfo("requested item: " .. itmDump)
    return nil
  end
  
  local result = shared.controller:tryTakeItem(item)
  if result and result.count > 0 then
    --world.spawnItem(result, world.entityPosition(player))
    world.sendEntityMessage(player, "playerext:giveItemToCursor", result, true)
  end
end
