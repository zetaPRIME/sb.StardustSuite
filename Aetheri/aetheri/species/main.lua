-- Aetheri tech override - this one's gonna get *big* (so it's in modules for better navigation!)

-- common libraries
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/lib/stardust/tables.lua"
require "/lib/stardust/itemutil.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/tech/input.lua"

-- and modules
require "/aetheri/species/stats.lua"
require "/aetheri/species/movement.lua"
require "/aetheri/species/appearance.lua"
require "/aetheri/species/hud.lua"

function init()
  appearance.updateColors()
  -- figure out which state we want to start out in
  if mcontroller.liquidMovement or (world.gravity(mcontroller.position()) == 0) or status.statusProperty("fu_byosnogravity", false) then
    movement.enterState("flight")
  else movement.enterState("ground") end
end

function uninit()
  movement.callState("uninit")
  stats.uninit()
end

function update(p)
  stats.update(p)
  input.update(p)
  movement.update(p)
  appearance.update(p)
  hud.update(p)
end















--
