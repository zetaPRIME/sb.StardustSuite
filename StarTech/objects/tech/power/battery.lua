--

require "/lib/stardust/prefabs.lua"
require "/lib/stardust/power.lua"

function init()
  local cfg = config.getParameter("batteryStats")
  battery = prefabs.fluxpulse.battery(cfg.capacity, cfg.ioRate):hookUp():autoSave()
end

function update()
  power.autoSendEnergy(1000000000)
  object.say(string.format("%dFP", math.floor(battery.state.energy)))
end
