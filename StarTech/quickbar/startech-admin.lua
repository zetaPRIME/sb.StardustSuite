require "/lib/stardust/power.item.lua"

function module.recharge()
  while power.fillEquipEnergy(573000) > 0 do end -- max-fill until nothing can recharge further
end
