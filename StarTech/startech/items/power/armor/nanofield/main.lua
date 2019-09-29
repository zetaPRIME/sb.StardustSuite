--

require "/scripts/vec2.lua"
require "/lib/stardust/itemutil.lua"
require "/lib/stardust/tech/input.lua"

require "/startech/items/power/armor/nanofield/stats.lua"
require "/startech/items/power/armor/nanofield/movement.lua"
require "/startech/items/power/armor/nanofield/appearance.lua"

-- armor value works differently from normal armors
-- mult = .5^(armor/100); or, every 100 points is a 50% damage reduction

function update(p)
  input.update(p)
  stats.update(p)
  
  movement.update(p)
  
  stats.postUpdate(p)
  appearance.update(p)
  
  --
end

function uninit()
  movement.call("uninit")
  stats.uninit()
end
