require "/scripts/vec2.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/tasks.lua"

storagenet = { }

function storagenet:onConnect()
  
end

function storagenet:onDisconnect()
  
end

local queue = taskQueue()

local svc = { }
local openPlayers = { }
local playerTimeout = -1
local inUse
local lastUsedBy

local function dbg(txt)
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

function svc.rectify()
  if not storagenet.connected then return end
  queue:spawn("rectify", function()
    storagenet:transaction { "rectify" }:runUntilFinish()
    object.say("Check complete.")
  end)
end

-- player tracking
function svc.playerOpen(msg, isLocal, pid)
  openPlayers[pid] = true
  lastUsedBy = pid
  playerTimeout = math.floor(60 * 0.5) -- give some extra time to account for potential client lag on loading
end

function svc.playerClose(msg, isLocal, pid)
  openPlayers[pid] = nil
end

function svc.playerHeartbeat(msg, isLocal, pid)
  playerTimeout = math.max(playerTimeout, math.floor(60 * 0.25))
  openPlayers[pid] = true -- might as well pick back up
end

-- -- --

function init()
  for k, v in pairs(svc) do message.setHandler(k, v) end
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
  
  queue()
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
