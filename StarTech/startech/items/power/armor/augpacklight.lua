--
require "/scripts/util.lua"
require "/lib/stardust/eventhook.lua"

function init()
  eventHook.subscribeClient("stardustlib:drawLocal", draw)
end

local rate = 5
local light = 0
-- smoothed rate-limited sampling
local getLight = coroutine.wrap(function()
  while true do
    local n = world.lightLevel(mcontroller.position())
    local s = (n - light) / rate
    for i=1,rate do
      light = light + s
      coroutine.yield()
    end
  end
end)

local min = 0.25
function draw(localAnimator)
  local pos = mcontroller.position()
  --local light = world.lightLevel(pos)
  getLight()
  local res = util.clamp( (1.0 - ((light-0.3) / 0.5)) ^ 0.5, min, 1)
  --chat.addMessage("lighting level is " .. light .. "; res is " .. res)
  -- scale to max at 0.3, zero at 0.7
  
  localAnimator.addLightSource {
    active = true,
    position = pos,
    color = {190*res, 190*res, 190*res},
    pointLight = true,
  }
end
