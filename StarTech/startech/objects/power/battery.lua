--

require "/lib/stardust/prefabs.lua"
require "/lib/stardust/power.lua"
require "/lib/stardust/network.lua"
require "/lib/stardust/color.lua"

function init()
  local cfg = config.getParameter("batteryStats")
  battery = prefabs.power.battery(cfg.capacity, cfg.ioRate):hookUp():autoSave():controlTickrate()
  
  message.setHandler("wrenchInteract", onWrench)
  dDesc = config.getParameter("baseDescription")--root.itemConfig({ name = object.name(), count = 1 }).config.description
  tDesc = 573000000
  
  isRelay = config.getParameter("isRelay")
  
  -- set all outputs positive for chunkloading purposes
  for i=1, object.outputNodeCount() do object.setOutputNodeLevel(i-1, true) end
end

function postInit() -- run on first update, after everything is loaded
  fuNetworkKickstart() -- kickstart anything this loaded after
end

function update()
  if not storage.loaded then
    battery.state.energy = world.getObjectParameter(entity.id(), "storedEnergy") or battery.state.energy -- we don't actually have to drain
    storage.loaded = true
  end
  
  if postInit then postInit() postInit = nil end
  
  power.autoSendEnergy(1000000000)
  
  if not isRelay then
    -- only applies to actual batteries
    object.setAnimationParameter("level", battery.state.energy / battery.capacity)
    tDesc = tDesc + 1
    if tDesc >= 10 then
      tDesc = 0
      if battery.state.energy ~= lastDescEnergy then
        object.setConfigParameter("description", getDescription())
        lastDescEnergy = battery.state.energy
      end
    end
    --if storage.alwaysDisplay then sayLevel() end
  end
end

function getDescription()
  return string.format("%s\n^green;%d^darkgreen;/^green;%d^darkgreen;FP^reset;", dDesc, math.floor(battery.state.energy), math.floor(battery.capacity))
end

function sayLevel()
  object.say(string.format("%dFP", math.floor(battery.state.energy)))
end

function onWrench(msg, isLocal, player, shiftHeld)
  if shiftHeld then
    brokenByPlr = player
    object.smash() -- quick break a la modded-Minecraft
  end
end

function die()
  if isRelay then return nil end -- custom drop logic only applicable to batteries
  local itm = {
    name = config.getParameter("objectName"),
    count = 1,
    parameters = {}
  }
  if battery.state.energy >= 1 then
    itm.parameters.storedEnergy = battery.state.energy
    itm.parameters.description = getDescription()
    
    local batLevel = battery.state.energy / battery.capacity
    itm.parameters.inventoryIcon = {
      { image = config.getParameter("iconBaseImage") or "battery.frame.png" },
      {
        image = table.concat({
          "battery.meter.png?addmask=/startech/objects/power/battery.meter.png", ";0;",
          10 - math.floor(batLevel * 10),
          "?multiply=", color.toHex(color.fromHsl{math.max(0, batLevel*1.25 - 0.25) * 1/3, 1, 0.5, 1})
        }), 
        fullbright = true
      }
    }
    --itm.parameters.largeImage = itm.parameters.inventoryIcon -- maybe?
  end
  world.spawnItem(itm, world.entityPosition(brokenByPlr or entity.id()))
  object.smash(true)
end

-- FU translation
function fuNetworkKickstart()
  local pool = network.getPool()
  for _,id in pairs(pool) do
    --sb.logInfo("kicking " .. id .. ", type " .. (world.callScriptedEntity(id, "config.getParameter", "name") or world.callScriptedEntity(id, "config.getParameter", "objectName")))
    world.callScriptedEntity(id, "power.onNodeConnectionChange") -- force FU power network update, if applicable
  end
end
function isPower() return "battery" end
function power.onNodeConnectionChange(arg) return arg end
function power.getEnergy()
  return battery.state.energy * power.translationFactorFU
end
function power.getMaxEnergy()
  return battery.capacity * power.translationFactorFU
end
function power.getStorageLeft()
  return (battery.capacity - battery.state.energy) * power.translationFactorFU
end
function power.recievePower(amt)
  -- can't really rate limit, since pushing from FU things isn't generally per-tick
  amt = amt / power.translationFactorFU -- convert units
  battery.state.energy = math.min(battery.state.energy + amt, battery.capacity)
  battery:consume(0, true) -- trigger postupdate
end
function power.remove(amt)
  battery:consume(amt / power.translationFactorFU) -- I guess use this
end
