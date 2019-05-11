stats = { stat = { }, flags = { } }

local baseStats = {
  health = 100,
  energy = 100,
  armor = 0,
  damageMult = 1,
  skillDamageMult = 1,
  
  
}

-- stats.values, stats.flags,

-- base, add, inc, more

function stats.refresh()
  -- nothing for now
  stats.stat = { }
  for k, v in pairs(baseStats) do
    stats.stat[k] = v -- for now just set to base stats
  end
  
  tech.setStats {
    { stat = "maxHealth", amount = -100 + stats.stat.health },
    { stat = "maxEnergy", amount = -100 + stats.stat.energy },
    { stat = "protection", amount = stats.stat.armor },
    { stat = "powerMultiplier", baseMultiplier = stats.stat.damageMult },
    { stat = "aetheri:skillPowerMultiplier", amount = stats.stat.skillDamageMult },
  }
end

message.setHandler("aetheri:gainAP", function(msg, isLocal, amt)
  status.setStatusProperty("aetheri:AP", amt + status.statusProperty("aetheri:AP", 0))
  hud.gainAP(amt)
end)

message.setHandler("aetheri:refreshStats", stats.refresh)
stats.refresh() -- do this at the beginning
