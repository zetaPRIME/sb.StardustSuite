stats = { stat = { }, flags = { } }

local baseStats = {
  health = 100,
  healthRegen = 0,
  energy = 100,
  energyRegen = 50,
  mana = 250,
  manaRegen = 5,
  armor = 0,
  damageMult = 1,
  skillDamageMult = 1,
  
  airJumps = 1,
}

-- base, add, inc, more

local equipStatsUpdated
function stats.forceEquipUpdate() equipStatsUpdated = true end
function stats.refresh()
  stats.stat = { }
  local cstats
  
  -- load in calculated stats if still valid, or base stats if not
  local skdata = status.statusProperty("aetheri:skillTreeData", nil)
  if skdata and skdata.compatId ~= root.assetJson("/aetheri/species/skilltree.config:compatId") then skdata = nil end
  if skdata and skdata.calculatedStats then cstats = skdata.calculatedStats
  else cstats = root.assetJson("/aetheri/species/skilltree.config:baseStats")
  end
  
  for k, v in pairs(cstats) do -- calculate final stat values
    stats.stat[k] = (v[1] or 0) * (v[2] or 1.0) * (v[3] or 1.0)
  end
  
  tech.setStats { -- apply relevant stats
    { stat = "maxHealth", amount = -100 + stats.stat.health },
    { stat = "healthRegen", amount = stats.stat.healthRegen },
    { stat = "maxEnergy", amount = -100 + stats.stat.energy },
    --{ stat = "energyRegenPercentageRate", baseMultiplier = 0, asmount = stats.stat.energyRegen }, -- this one is... messy
    { stat = "aetheri:maxMana", amount = stats.stat.mana },
    { stat = "aetheri:manaRegen", amount = stats.stat.manaRegen },
    { stat = "protection", amount = stats.stat.armor },
    { stat = "powerMultiplier", baseMultiplier = stats.stat.damageMult },
    { stat = "aetheri:skillPowerMultiplier", amount = stats.stat.skillDamageMult },
  } --equipStatsUpdated = true
  
  local sp = status.statusProperty("aetheri:statusPersist", nil)
  if sp then -- restore resource values after teleport or reload
    status.setResource("health", sp.health)
    status.setResource("energy", sp.energy)
    status.setResource("aetheri:mana", sp.mana)
    -- then clear property when we're done
    status.setStatusProperty("aetheri:statusPersist", nil)
  end
end

local equipSlots = { "head", "chest", "legs" }
function stats.update(p)
  for _, s in pairs(equipSlots) do -- maintain equipment slots
    -- TODO: visual stuff; keep track of resource values to reinstate after the chestpiece is bumped out
    local lf = "aetheri:innate" .. s
    local si = playerext.getEquip(s) or itemutil.blankItem
    if equipStatsUpdated or si.name ~= lf then
      playerext.setEquip(s, { name = lf, count = 1, parameters = {
        --statusEffects = (s == "chest") and equipStats or nil
      } })
      local ci = playerext.getEquip("cursor") or itemutil.blankItem
      if ci.name == lf then
        playerext.setEquip("cursor", si)
      elseif si.name ~= lf then -- if actually removed and not picked up in cursor (mannequin, for example), bump into inventory
        playerext.giveItems(si)
      end
    end
  end
  equipStatsUpdated = false -- doop
  
  --if not status.resourcePositive("energyRegenBlock") then status.modifyResource("energy", stats.stat.energyRegen * p.dt) end
end

function stats.uninit()
  -- save stuff
  status.setStatusProperty("aetheri:statusPersist", {
    health = status.resource("health"),
    energy = status.resource("energy"),
    mana = status.resource("aetheri:mana"),
  })
  
end

message.setHandler("aetheri:gainAP", function(msg, isLocal, amt)
  status.setStatusProperty("aetheri:AP", amt + status.statusProperty("aetheri:AP", 0))
  hud.gainAP(amt)
end)

message.setHandler("aetheri:refreshStats", stats.refresh)
stats.refresh() -- do this at the beginning
