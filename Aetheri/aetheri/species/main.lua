-- Aetheri tech override - this one's gonna get *big* (so it's in modules for better navigation!)

-- common libraries
require "/lib/stardust/playerext.lua"

-- and modules
require "/aetheri/species/appearance.lua"

function init()
  appearance.updateColors()
end

function update(p)
  appearance.update(p)
end















--
