--

require "/lib/stardust/prefabs.lua"
require "/lib/stardust/power.lua"

local fuelStats = {
  coalore = { -- 8 1/3 seconds at 10FP/t for a total of 5000FP per coal... or 5.5sec at 15FP/t
    burnTime = 500,
    powerPerTick = 10 -- pretty sure 10/t is final, not so sure of duration
  }
}
function getFuelStats(item)
  if not item.count then return nil end -- early out on null item
  return fuelStats[item.name]
end

function init()
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
