-- Aetheri tech override - this one's gonna get *big* (so it's in modules for better navigation!)

-- common libraries
require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/lib/stardust/playerext.lua"

-- and modules
require "/aetheri/species/input.lua"
require "/aetheri/species/appearance.lua"
--require "/aetheri/species/hud.lua"

function init()
  appearance.updateColors()
end

function update(p)
  input.update(p)
  appearance.update(p)
end















--
