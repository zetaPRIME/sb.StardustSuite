--
require "/lib/stardust/eventhook.lua"

function init()
  eventHook.subscribeClient("stardustlib:drawLocal", draw)
end

function draw(localAnimator)
  localAnimator.addLightSource {
    active = true,
    position = mcontroller.position(),
    color = {190, 190, 190},
    pointLight = true,
  }
end
