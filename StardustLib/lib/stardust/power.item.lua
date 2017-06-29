require "/lib/stardust/itemutil.lua"
require "/lib/stardust/power.lua"

--[[
parameters.batteryStats {
  energy
  capacity
  ioRate
}
]]

function power.drawItemEnergy(item, amount, testOnly)
  if not item.count then return 0 end -- no item here!
  local cfg = itemutil.getCachedConfig(item)
  if not cfg.batteryStats and not item.parameters.batteryStats then return 0 end -- no internal battery
  
  -- assemble actual battery stats
  local bs = copy(cfg.batteryStats or {})
  for k,v in pairs(item.parameters.batteryStats or {}) do bs[k] = v end
  
  -- calculate how much can actually be taken
  local r = math.min(amount, bs.ioRate or amount)
  r = math.min(r, bs.energy or 0)
  
  if not testOnly then -- actually remove
    if not item.parameters.batteryStats then item.parameters.batteryStats = {} end
    item.parameters.batteryStats.energy = bs.energy - r
  end
  
  return r
end

function power.drawEquipEnergy(amount, testOnly)
  if not player then return 0 end -- abort if player table is unavailable
  local acc = 0
  
  local slots = {
    "back",
    "chest",
    "legs",
    "head"
  }
  
  for k,slot in pairs(slots) do
    -- check each slot
    local item = player.equippedItem(slot)
    local amt = power.drawItemEnergy(item, amount - acc, testOnly) -- try to draw from equipped item
    --sb.logInfo("slot " .. slot .. ": drew " .. amt .. "FP")
    acc = acc + amt -- accumulate...
    if amt > 0 and not testOnly then player.setEquippedItem(slot, item) end -- update item if capacity changed
    if acc >= amount then return acc end -- early out when quota reached
  end
  
  --sb.logInfo("drew " .. acc .. " total")
  return acc
end









--
