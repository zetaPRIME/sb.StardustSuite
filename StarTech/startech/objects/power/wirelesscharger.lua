--

require "/lib/stardust/prefabs.lua"
require "/lib/stardust/power.lua"
require "/lib/stardust/network.lua"

iou = { } -- table of promises for sent power
commit = 0 -- how much of the battery has been committed
baseDelta = 15 -- ticks between updates while active
idleDelta = 60 -- ticks between updates while idle (no charge)

function init()
  local cfg = config.getParameter("batteryStats")
  battery = prefabs.power.battery(cfg.capacity, cfg.ioRate):hookUp():autoSave()
  range = config.getParameter("tileRange")
  packetSize = cfg.ioRate
  script.setUpdateDelta(baseDelta)
end

function update()
  local active = false
  for k, p in pairs(iou) do
    if p:finished() then
      if p:succeeded() then
        local taken = p:result()
        battery.state.energy = battery.state.energy - taken
        if taken > 0 then active = true end
      end
      commit = commit - packetSize
      iou[k] = nil
    end
  end
  
  if battery.state.energy > commit + packetSize then -- only if more exists than committed
    local pl = world.playerQuery(entity.position(), range)
    for _, p in pairs(pl) do
      local ps = math.min(battery.state.energy - commit, packetSize)
      if ps <= 0 then break end -- no energy to give
      --active = true
      totalGiven = ps
      commit = commit + ps
      iou[{ }] = world.sendEntityMessage(p, "playerext:fillEquipEnergyAsync", ps, baseDelta)
    end
  end
  
  -- slow updates when not actively charging
  script.setUpdateDelta(active and baseDelta or idleDelta)
  
  --object.say(string.format("energy: %0.2f\ncommit: %0.2f\nactive: %s", battery.state.energy, commit, active and "y" or "n"))
end
