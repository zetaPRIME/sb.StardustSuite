stats = { stat = { }, flags = { } }

-- base, add, inc, more

local equipStatsUpdated
function stats.forceEquipUpdate() equipStatsUpdated = true end
function stats.refresh()
  stats.stat = { }
  local cstats
  
  -- load in calculated stats if still valid, or base stats if not
  local skdata = status.statusProperty("aetheri:skillTreeData", nil)
  if skdata and skdata.compatId ~= root.assetJson("/aetheri/species/skilltree.config:compatId") then -- if tree changed then reset and refund
    --status.setStatusProperty("aetheri:AP", status.statusProperty("aetheri:AP", 0) + (skdata.spentAP or 0))
    skdata = nil
  end
  if skdata and skdata.calculatedStats then cstats = skdata.calculatedStats
  else cstats = { }
  end
  
  for k, v in pairs(cstats) do -- calculate final stat values
    stats.stat[k] = (v[1] or 0) * (v[2] or 1.0) * (v[3] or 1.0)
  end
  
  local baseStats = root.assetJson("/aetheri/species/skilltree.config:baseStats")
  for k, v in pairs(baseStats) do -- populate missing stats with base values
    if not stats.stat[k] then stats.stat[k] = (v[1] or 0) * (v[2] or 1.0) * (v[3] or 1.0) end
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
    
    { stat = "aetheri:miningSpeed", amount = stats.stat.miningSpeed },
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
  if status.resource("health") > 0 then
    -- save resource values on teleport (but not death)
    status.setStatusProperty("aetheri:statusPersist", {
      health = status.resource("health"),
      energy = status.resource("energy"),
      mana = status.resource("aetheri:mana"),
    })
  end
  
end

message.setHandler("aetheri:gainAP", function(msg, isLocal, amt)
  status.setStatusProperty("aetheri:AP", amt + status.statusProperty("aetheri:AP", 0))
  hud.gainAP(amt)
end)

message.setHandler("aetheri:refreshStats", stats.refresh)
stats.refresh() -- do this at the beginning

-- and hook into damage!
message.setHandler("stardustlib:modifyDamageTaken", function(_, _, damageRequest)
  if damageRequest.damageSourceKind == "falling" then
    if damageRequest.damage >= 50 then -- WIP: do something special on hard fall
      --[[local vol = 1.0
      sound.play("/sfx/melee/hammer_hit_ground1.ogg", vol * 1.5, 1) -- impact low
      sound.play("/sfx/gun/grenadeblast_small_electric2.ogg", vol * 1.125, 0.75) -- impact mid
      sound.play("/sfx/objects/essencechest_open1.ogg", vol * 0.75, 1) -- impact high
      -- zoops
      sound.play("/sfx/gun/erchiuseyebeam_start.ogg", vol * 1.0, 1)
      --]]
    else -- only a bit of a fall
      --[[local vol = 0.75
      sound.play("/sfx/melee/hammer_hit_ground1.ogg", vol * 1.15, 1) -- impact low
      sound.play("/sfx/gun/grenadeblast_small_electric2.ogg", vol * 0.5, 0.75) -- impact mid
      sound.play("/sfx/objects/essencechest_open1.ogg", vol * 0.75, 2) -- impact high
      --]]
    end
    damageRequest.damageSourceKind = "applystatus" -- cancel fall damage
    return damageRequest
  elseif damageRequest.damageType == "Damage" then -- normal damage, apply DR
    damageRequest.damageType = "IgnoresDef"
    damageRequest.damage = damageRequest.damage * (.5 ^ (status.stat("protection") / 100))
    return damageRequest
  end
end)

if not playerext.getEquip("beamaxe") then -- first startup stuff: set active skills if no essential items present
  local ess = { "beamaxe", "wiretool", "painttool", "inspectiontool" }
  
  local pd = status.statusProperty("aetheri:skillTreeData", { })
  pd.selectedSkills = { "dig", "burst", "none", "none" }
  status.setStatusProperty("aetheri:skillTreeData", pd)
  
  for i = 1, 4 do
    playerext.setEquip(ess[i], { name = "aetheri:skill." .. pd.selectedSkills[i], count = 1 })
  end
end













-- EOF --
