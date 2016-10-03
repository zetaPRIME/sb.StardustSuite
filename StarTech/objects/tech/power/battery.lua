--

require "/lib/stardust/prefabs.lua"
require "/lib/stardust/power.lua"

function init()
  --local cfg = config.getParameter("batteryStats")
  local cfg = {
    capacity = 10000,
    ioRate = 50
  }
  battery = prefabs.fluxpulse.battery(cfg.capacity, cfg.ioRate):hookUp():autoSave()
  -- test
  battery.state.energy = cfg.capacity / 2
end

function update()
  power.autoSendEnergy(1000000000)
  object.say(string.format("%dFP", math.floor(battery.state.energy)))
end
