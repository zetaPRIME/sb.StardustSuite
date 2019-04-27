require "/lib/stardust/itemutil.lua"
require "/lib/stardust/playerext.lua"

local tierReqs = {
  { name = "ironbar", count = 5 },
  { name = "tungstenbar", count = 5 },
  { name = "titaniumbar", count = 15 },
  { name = "durasteelbar", count = 20 },
  { name = "refinedviolium", count = 20 },
  { name = "solariumstar", count = 20 },
}

function module.upgradeNanofield()
  --while power.fillEquipEnergy(573000) > 0 do end -- max-fill until nothing can recharge further
  local nf = player.equippedItem("chest") or { }
  if nf.name ~= "startech:nanofield" then
    playerext.message("Nanofield must be worn in order to upgrade.")
    return nil
  end
  nf.parameters = nf.parameters or { }
  local tier = itemutil.property(nf, "/moduleSystem/tierCatalyst")
  local req = tierReqs[tier + 1]
  if not req then
    playerext.message("Nanofield is already max tier (" .. tier .. ").")
    return nil
  end
  if player.consumeItem(req, false) then
    nf.parameters.moduleSystem = nf.parameters.moduleSystem or { }
    nf.parameters.moduleSystem.tierCatalyst = tier + 1
    player.setEquippedItem("chest", nf)
    world.sendEntityMessage(player.id(), "startech:nanofield.update")
    local msg = "Nanofield upgraded to Tier " .. tier + 1 .. ".\nCost: " .. req.count .. " " .. itemutil.property(req, "shortdescription") .. "."
    local nextreq = tierReqs[tier+2]
    if nextreq then msg = msg .. "\nNext tier requires: " .. nextreq.count .. " " .. itemutil.property(nextreq, "shortdescription") .. "." end
    playerext.message(msg)
  else
    playerext.message("Tier " .. tier + 1 .. " Nanofield upgrade requires: " .. req.count .. " " .. itemutil.property(req, "shortdescription") .. ".")
  end
end
