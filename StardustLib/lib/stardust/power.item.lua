require "/scripts/util.lua"

require "/lib/stardust/itemutil.lua"
require "/lib/stardust/power.lua"

--[[
parameters.batteryStats {
  energy
  capacity
  ioRate
}
]]

function power.fillItemEnergy(item, amount, testOnly, ioMult)
  ioMult = ioMult or 1.0
  if not item or not item.count or item.count <= 0 then return 0 end -- no item here!
  local cfg = itemutil.getCachedConfig(item)
  if not cfg.config.batteryStats and not item.parameters.batteryStats then return 0 end -- no internal battery
  
  -- assemble actual battery stats
  local bs = copy(cfg.config.batteryStats or {})
  for k,v in pairs(item.parameters.batteryStats or {}) do bs[k] = v end
  bs.energy = bs.energy or 0
  
  -- calculate how much can actually be added
  local r = math.min(amount, (bs.ioRate or math.huge) * ioMult)
  r = math.min(r, (bs.capacity - bs.energy) or 0)
  
  if not testOnly then -- actually fill
    if not item.parameters.batteryStats then item.parameters.batteryStats = {} end
    item.parameters.batteryStats.energy = bs.energy + r
  end
  
  return r
end

function power.drawItemEnergy(item, amount, testOnly, ioMult)
  ioMult = ioMult or 1.0
  if not item or not item.count or item.count <= 0 then return 0 end -- no item here!
  local cfg = itemutil.getCachedConfig(item)
  if not cfg.config.batteryStats and not item.parameters.batteryStats then return 0 end -- no internal battery
  
  -- assemble actual battery stats
  local bs = copy(cfg.config.batteryStats or {})
  for k,v in pairs(item.parameters.batteryStats or {}) do bs[k] = v end
  bs.energy = bs.energy or 0
  
  -- calculate how much can actually be taken
  local r = math.min(amount, (bs.ioRate or math.huge) * ioMult)
  r = math.min(r, bs.energy or 0)
  
  if not testOnly then -- actually remove
    if not item.parameters.batteryStats then item.parameters.batteryStats = {} end
    item.parameters.batteryStats.energy = bs.energy - r
  end
  
  return r
end

function power.fillEquipEnergy(amount, testOnly, ioMult)
  if not player then return 0 end -- abort if player table is unavailable
  local function msg() world.sendEntityMessage(entity.id(), "stardustlib:onFillEquipEnergy") end
  local acc = 0
  
  if not status.resourceLocked("stardustlib:fluxpulse") then -- fill internal battery if present
    local internal = math.min(amount, status.resourceMax("stardustlib:fluxpulse") - status.resource("stardustlib:fluxpulse"))
    acc = acc + internal
    if not testOnly then status.giveResource("stardustlib:fluxpulse", internal) end
    if acc >= amount then msg() return acc end
  end
  
  local slots = {
    "back",
    "chest",
    "legs",
    "head"
  }
  
  for k,slot in pairs(slots) do
    -- check each slot
    local item = player.equippedItem(slot)
    local amt = power.fillItemEnergy(item, amount - acc, testOnly, ioMult) -- try to fill equipped item
    acc = acc + amt -- accumulate...
    if amt > 0 and not testOnly then player.setEquippedItem(slot, item) end -- update item if capacity changed
    if acc >= amount then msg() return acc end -- early out when quota reached
  end
  
  if acc >= 0 then msg() end
  return acc
end

function power.drawEquipEnergy(amount, testOnly, ioMult)
  if not player then return 0 end -- abort if player table is unavailable
  local function msg() world.sendEntityMessage(entity.id(), "stardustlib:onDrawEquipEnergy") end
  local acc = 0
  
  if not status.resourceLocked("stardustlib:fluxpulse") then -- draw from internal battery if present
    local internal = math.min(amount, status.resource("stardustlib:fluxpulse"))
    acc = acc + internal
    if not testOnly then status.overConsumeResource("stardustlib:fluxpulse", internal) end
    if acc >= amount then msg() return acc end
  end
  
  local slots = {
    "back",
    "chest",
    "legs",
    "head"
  }
  
  for k,slot in pairs(slots) do
    -- check each slot
    local item = player.equippedItem(slot)
    local amt = power.drawItemEnergy(item, amount - acc, testOnly, ioMult) -- try to draw from equipped item
    --sb.logInfo("slot " .. slot .. ": drew " .. amt .. "FP")
    acc = acc + amt -- accumulate...
    if amt > 0 and not testOnly then player.setEquippedItem(slot, item) end -- update item if capacity changed
    if acc >= amount then msg() return acc end -- early out when quota reached
  end
  
  if acc >= 0 then msg() end
  return acc
end

function power.fillContainerEnergy(id, amount, testOnly, ioMult)
  local acc = 0
  
  local contents = world.containerItems(id)
  if not contents then return 0 end -- abort if not a container, silly
  
  for slot,item in pairs(contents) do
    -- check each slot
    local amt = power.fillItemEnergy(item, amount - acc, testOnly, ioMult) -- try to fill equipped item
    acc = acc + amt -- accumulate...
    if amt > 0 and not testOnly then
      -- update container contents
      world.containerTakeAt(id, slot-1) -- might not be necessary, but let's avoid weirdness anyway
      world.containerSwapItems(id, item, slot-1)
    end
    if acc >= amount then return acc end -- early out when quota reached
  end
  
  return acc
end








--
