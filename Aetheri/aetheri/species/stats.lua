stats = { }

local baseStats = {
  health = 100,
  energy = 100,
  armor = 0,
}

-- base, add, inc, more

function stats.refresh()
  -- nothing for now
end

message.setHandler("aetheri:gainAP", function(msg, isLocal, amt)
  hud.gainAP(amt)
end)

message.setHandler("aetheri:refreshStats", stats.refresh)
stats.refresh() -- do this at the beginning
