--

stats = { stat = { }, item = { } }

local tierBaseStats = { -- keeping this temporarily for reference
  { -- T1 (Iron)
    armor = 20,
    health = 110,
    energy = 110,
    damageMult = 1.5,
  },
  { -- T2 (Tungsten) (default)
    armor = 40,
    health = 120,
    energy = 120,
    damageMult = 2.0,
  },
  { -- T3 (Titanium)
    armor = 120,
    health = 130,
    energy = 130,
    damageMult = 2.5,
  },
  { -- T4 (Durasteel)
    armor = 160,
    health = 140,
    energy = 140,
    damageMult = 3.0,
  },
  { -- T5 (Violium/Ferozium/Aegisalt)
    armor = 200,
    health = 150,
    energy = 150,
    damageMult = 3.5,
  },
  { -- T6 (Solarium)
    armor = 240,
    health = 160,
    energy = 160,
    damageMult = 4.0,
  },
  { -- T7 (Ancient)
    armor = 275,
    health = 170,
    energy = 170,
    damageMult = 4.5,
  },
}

local staticitm = "startech:nanofieldstatic"

function stats.update(p)
  stats.item = playerext.getEquip("chest") or { }
  stats.itemModified = false
  if stats.item.name ~= "startech:nanofield" then
    return nil -- abort when no longer equipped
  end
  stats.level = itemutil.property(stats.item, "level") or 2
  if stats.item.parameters.moduleSystem then -- carry over old leveling
    stats.level = stats.item.parameters.moduleSystem.tierCatalyst or stats.level
    stats.item.parameters.moduleSystem = nil
    stats.item.parameters.level = stats.level
    stats.itemModified = true
  end
  stats.skillData = stats.item.parameters["stardustlib:skillData"] or { }
  stats.flags = stats.skillData.flags or { }
  stats.stat = { }
  for k,v in pairs(stats.skillData.stats) do
    stats.stat[k] = (v[1] or 0) * (v[2] or 1) * (v[3] or 1)
  end
  
  -- maintain other slots
  for _, slot in pairs{"head", "legs"} do
    local itm = playerext.getEquip(slot) or { name = "manipulatormodule", count = 0 }
    if itm.name ~= staticitm .. slot then
      if (playerext.getEquip(slot .. "Cosmetic") or { }).count ~= 1 then
        playerext.setEquip(slot .. "Cosmetic", itm)
      else
        playerext.giveItems(itm)
      end
      playerext.setEquip(slot, { -- clear slot afterwards so that the slot isn't empty during giveItems
        name = staticitm .. slot,
        count = 1
      })
      -- clear out static if picked up
      if (playerext.getEquip("cursor") or { }).name == staticitm .. slot then
        playerext.setEquip("cursor", { name = "", count = 0 })
        if slot == "legs" then
          playerext.openUI("startech:configurator.nanofield")
        end
      end
    end
  end
  
end

function stats.postUpdate(p)
  
  local sg = {
    { stat = "startech:wearingNanofield", amount = 1 },
    
    { stat = "breathProtection", amount = 1 },
    --{ stat = "nude", amount = -100 },
    
    --[[{ stat = "protection", amount = stats.stat.armor },
    { stat = "maxHealth", amount = stats.stat.health - 100 },
    { stat = "maxEnergy", amount = stats.stat.energy - 100 },
    { stat = "powerMultiplier", baseMultiplier = stats.stat.damageMult },]]
  }
  movement.call("updateEffectiveStats", sg)
  tech.setStats(sg)
  
  if stats.itemModified then
    playerext.setEquip("chest", stats.item)
  end
end

function stats.uninit()
  -- destroy ephemera on unequip
  for _, slot in pairs{"head", "legs"} do
    local itm = playerext.getEquip(slot) or { }
    if itm.name == staticitm .. slot then
      playerext.setEquip(slot, { name = "", count = 0 }) -- clear item
    end
  end
end

function stats.drawEnergy(amount, testOnly, ioMult)
  if amount <= 0 then return true end
  local res = playerext.drawEquipEnergy(amount, testOnly, ioMult)
  if not testOnly then -- update cached item's capacitor
    stats.item.parameters.batteryStats = playerext.getEquip("chest").parameters.batteryStats
  end
  return res >= amount
end

message.setHandler("stardustlib:modifyDamageTaken", function(msg, isLocal, damageRequest)
  if damageRequest.damageSourceKind == "falling" then
    if damageRequest.damage >= 50 then -- do something special on hard fall
      local vol = 1.0
      sound.play("/sfx/melee/hammer_hit_ground1.ogg", vol * 1.5, 1) -- impact low
      sound.play("/sfx/gun/grenadeblast_small_electric2.ogg", vol * 1.125, 0.75) -- impact mid
      sound.play("/sfx/objects/essencechest_open1.ogg", vol * 0.75, 1) -- impact high
      -- zoops
      --sound.play("/sfx/gun/erchiuseyebeam_start.ogg", vol * 1.5, 0.333)
      sound.play("/sfx/gun/erchiuseyebeam_start.ogg", vol * 1.0, 1)
      appearance.pulseForceField(3) -- long pulse
      movement.call("onHardFall")
    else -- only a bit of a fall
      local vol = 0.75
      sound.play("/sfx/melee/hammer_hit_ground1.ogg", vol * 1.15, 1) -- impact low
      sound.play("/sfx/gun/grenadeblast_small_electric2.ogg", vol * 0.5, 0.75) -- impact mid
      sound.play("/sfx/objects/essencechest_open1.ogg", vol * 0.75, 2) -- impact high
      appearance.pulseForceField(0.5) -- pulse a bit
    end
    damageRequest.damageSourceKind = "applystatus" -- cancel fall damage
    return damageRequest
  elseif damageRequest.damageType == "Damage" then -- normal damage, apply DR
    local powered = stats.drawEnergy(damageRequest.damage * 25, false, 60)
    if powered then
      sound.play("/sfx/melee/charge_full_swing2.ogg") -- shield sound
      appearance.pulseForceField() -- visual field effect!
    end
    local def = status.stat("protection") * (powered and 1.0 or 0.5)
    damageRequest.damageType = "IgnoresDef"
    damageRequest.damage = damageRequest.damage * (.5 ^ (def / 100))
    return damageRequest
  end
end)

message.setHandler("stardustlib:statusImbueQuery", function()
  world.sendEntityMessage(entity.id(), "stardustlib:statusImbueQueryReply", {
    '::{"tag":"antiSpace"}',
  })
end)
