--
require "/lib/stardust/playerext.lua"

function init()
  script.setUpdateDelta(1)
end

function update()
  playerext.queueLight {
    active = true,
    position = mcontroller.position(),
    color = {190, 190, 190},
    pointLight = true,
  }
end
