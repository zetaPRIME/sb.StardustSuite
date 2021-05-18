require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  script.setUpdateDelta(1)
end

function update()
  --local vel = vec2.mag(mcontroller.velocity())
  --animator.setParticleEmitterBurstCount("dashParticles", math.floor(0.5 + util.lerp(util.clamp(vel/50, 0, 1), 1, 5)))
  animator.setParticleEmitterBurstCount("dashParticles", 5)
  animator.burstParticleEmitter("dashParticles")
end
