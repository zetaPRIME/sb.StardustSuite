--
require "/lib/stardust/eventhook.lua"

function init()
  if getmetatable''.clientSide then
    eventHook.subscribe("stardustlib:drawLocal", draw)
  end
end

function draw(localAnimator)
  localAnimator.addLightSource {
    active = true,
    position = mcontroller.position(),
    color = {190, 190, 190},
    pointLight = true,
  }
end
