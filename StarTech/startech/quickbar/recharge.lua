require "/lib/stardust/power.item.lua"
while power.fillEquipEnergy(math.huge, false, math.huge) > 0 do end -- turbo-fill until nothing can recharge further
