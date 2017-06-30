--

require "/lib/stardust/prefabs.lua"
require "/lib/stardust/power.lua"

function getFuelStats(item)
  if not item.count then return nil end -- early out on null item
  return fuelStats[item.name]
end

function init()
  fuelStats = config.getParameter("fuelStats")
  
  local cfg = config.getParameter("batteryStats")
  battery = prefabs.power.battery(cfg.capacity, cfg.ioRate):hookUp():autoSave()
  storage.burning = storage.burning or {}
  burning = storage.burning -- alias
  burning.timeLeft = burning.timeLeft or 0
  burning.powerPerTick = burning.powerPerTick or 0
end

function update()
  -- handle fueling
  if burning.timeLeft > 0 then
    --battery:receive(0, burning.powerPerTick)
    battery.state.energy = math.min(battery.state.energy + burning.powerPerTick, battery.capacity) -- override capacitor IO rate
    burning.timeLeft = burning.timeLeft - 1
  elseif battery:receive(0, 1, true) > 0 then
    -- try to take a new item
    local items = world.containerItems(entity.id()) or {}
    for slot,item in pairs(items) do
      local stats = getFuelStats(item)
      if stats then
        burning.timeLeft = stats.burnTime
        burning.powerPerTick = stats.powerPerTick
        burning.item = { name = item.name, count = 1, parameters = item.parameters }
        
        --world.containerTakeNumItemsAt(entity.id(), slot, 1)
        world.containerConsume(entity.id(), burning.item)
        break
      end
    end
  end
  
  -- and send from internal capacitor
  power.autoSendEnergy(1000000000)
  
  if battery.state.energy > 0 or burning.timeLeft > 0 then
    script.setUpdateDelta(1)
  else
    script.setUpdateDelta(30) -- slow down when inactive
  end
end
