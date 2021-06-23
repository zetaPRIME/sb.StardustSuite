require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/itemutil.lua"
require "/lib/stardust/tracking.lua"

storagenet = { }

local filter
local proxy

local rates = {
  30, 15, 8, 4, 2, 1
}
local maxSpeedUpgrades = #rates
local disconnectedRate, idleRate, drawRate
function updateRates()
  disconnectedRate = 60*5
  idleRate = 60
  drawRate = rates[1+storage.upgradeLevel]
end

local function proxyOnDisconnect(self)
  script.setUpdateDelta(disconnectedRate)
  proxy = nil -- clear variable
end

function storagenet:onConnect()
  tryHookUp()
end

local orientations = {
  { 0, -1 },
  { -1, 0 },
  { 0, 1 },
  { 1, 0 }
}
local orientName = { "down", "left", "up", "right" }

function tryHookUp()
  if proxy or not storagenet.connected then return end -- nope
  local spos = vec2.add(entity.position(), orientations[storage.orientation])
  proxy = containerProxy(spos)
  if not proxy then return end -- fail
  proxy.onDisconnect = proxyOnDisconnect
end

function setOrientation(o)
  storage.orientation = o
  object.setAnimationParameter("orientation", storage.orientation)
  if proxy then proxy:disconnect() end
  tryHookUp()
end

function setFilter(f)
  if f == "" then f = nil end
  storage.filter = f
  filter = f and itemutil.filter(f) or nil
end

-- -- --

local svc = { }

function svc.wrenchInteract(msg, isLocal, player, shiftHeld)
  if shiftHeld then
    return {
      interact = {
        id = entity.id(),
        type = "ScriptPane",
        config = { gui = { }, scripts = {"/metagui.lua"}, config = "startech:storagebus.config" }
      }
    }
  else
    setOrientation((storage.orientation % 4) + 1)
  end
end

function svc.getInfo() return { filter = storage.filter or "", priority = storage.priority } end
function svc.setInfo(msg, isLocal, filter, priority)
  local pr = ""--"Priority set: " .. storage.priority .. "\n"
  if filter == "" then
    setFilter()
    object.say(pr .. "Filter cleared")
  else
    setFilter(filter)
    object.say(pr .. "Filter set: " .. filter)
  end
end

local function match(itm)
  return not filter or filter(itm)
end

-- -- --

function init()
  if not storage.orientation then storage.orientation = 1 end
  if not storage.upgradeLevel then storage.upgradeLevel = 0 end
  object.setAnimationParameter("orientation", storage.orientation)
  setFilter(storage.filter) -- update
  
  object.setInteractive(false)
  
  for k, v in pairs(svc) do message.setHandler(k, v) end
  
  updateRates()
  script.setUpdateDelta(disconnectedRate)
end

function update(dt)
  tryHookUp() if not proxy then return end -- not connected, either to controller or container
  script.setUpdateDelta(idleRate) -- set delta to idle delay, then set back to configured delta if successful
  
  local maxDraw = 1--cfg.stackUpgrade and 99999 or 1
  
  local contents = proxy:outputContents()
  local idle = true
  for slot, itm in pairs(contents) do
    if match(itm) then
      local draw = math.min(itm.count, maxDraw)
      local taken = draw - (storagenet:transaction { "insert", 
        item = { name = itm.name, parameters = itm.parameters, count = draw }
      }:runUntilFinish().result or { count = 0 }).count
      if taken > 0 then
        world.containerConsumeAt(proxy.id, slot-1, taken)
        idle = false
        break
      end
    end
  end
  
  if idle then return end
  script.setUpdateDelta(drawRate) -- reset delta
end
