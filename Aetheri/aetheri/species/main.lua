-- Aetheri tech override - this one's gonna get *big* (so it's in modules for better navigation!)

-- common libraries
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/itemutil.lua"

-- and modules
require "/aetheri/species/stats.lua"
require "/aetheri/species/input.lua"
require "/aetheri/species/movement.lua"
require "/aetheri/species/appearance.lua"
require "/aetheri/species/hud.lua"

function init()
  appearance.updateColors()
  movement.enterState("ground")
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
