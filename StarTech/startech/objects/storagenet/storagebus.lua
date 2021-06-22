require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/itemutil.lua"

storagenet = { }

local provider = { }

local orientations = {
  { 0, -1 },
  { -1, 0 },
  { 0, 1 },
  { 1, 0 }
}
local orientName = { "down", "left", "up", "right" }














-- -- --

function init()
  if not storage.orientation then storage.orientation = 1 end
  if not storage.priority then storage.priority = 0 end
  object.setAnimationParameter("orientation", storage.orientation)
  
  object.setInteractive(false)
end
