require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"

function init()
  script.setUpdateDelta(1)
end

function update()
  local vel = vec2.mag(mcontroller.velocity())
  if vel >= 12 then
    animator.setParticleEmitterBurstCount("sparkParticles", math.floor(0.5 + util.lerp(util.clamp(vel/80, 0, 1), 1, 2)))
    animator.setParticleEmitterOffsetRegion("sparkParticles", rect.withSize(vec2.rotate({0, -2.5}, mcontroller.rotation()), vec2.mul(mcontroller.velocity(), -0.05)))
    animator.burstParticleEmitter("sparkParticles")
  end
  
  if vel >= 30 then script.setUpdateDelta(1)
  elseif vel >= 20 then script.setUpdateDelta(2)
  else script.setUpdateDelta(3) end
end
