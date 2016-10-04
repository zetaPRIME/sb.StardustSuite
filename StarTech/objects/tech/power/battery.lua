--

require "/lib/stardust/prefabs.lua"
require "/lib/stardust/power.lua"

function init()
  local cfg = config.getParameter("batteryStats")
  battery = prefabs.power.battery(cfg.capacity, cfg.ioRate):hookUp():autoSave()
  
  --message.setHandler("wrenchInteract", onWrench)
  dDesc = root.itemConfig({ name = object.name(), count = 1 }).config.description
  tDesc = 573000000
end

function update()
  if not storage.loaded then
    battery.state.energy = world.getObjectParameter(entity.id(), "storedEnergy") or battery.state.energy -- we don't actually have to drain
    storage.loaded = true
  end
  
  power.autoSendEnergy(1000000000)
  object.setAnimationParameter("level", battery.state.energy / battery.capacity)
  tDesc = tDesc + 1
  if tDesc >= 10 then
    tDesc = 0
    if battery.state.energy ~= lastDescEnergy then
      object.setConfigParameter("description", getDescription)
      lastDescEnergy = battery.state.energy
    end
  end
  --if storage.alwaysDisplay then sayLevel() end
end

function getDescription()
  return string.format("%s\n^green;%dFP/%dFP", dDesc, math.floor(battery.state.energy), math.floor(battery.capacity))
end

function sayLevel()
  object.say(string.format("%dFP", math.floor(battery.state.energy)))
end

function onWrench(msg, isLocal, player, shiftHeld)
  if shiftHeld then
    storage.alwaysDisplay = (not storage.alwaysDisplay) or nil
  else
    sayLevel()
    storage.alwaysDisplay = nil
  end
end

function die()
  local itm = {
    name = config.getParameter("objectName"),
    count = 1,
    parameters = {}
  }
  if battery.state.energy >= 1 then
    itm.parameters.storedEnergy = battery.state.energy
    itm.parameters.description = getDescription()
  end
  world.spawnItem(itm, entity.position())
  object.smash(true)
end
