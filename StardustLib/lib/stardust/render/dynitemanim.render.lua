require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  entityId = animationConfig.animationParameter("entityId")
end

local aaa = 0
local frontPivotOffset = {0.375, 0.125}
local backPivotOffset = {-0.25, 0.125}
function update(dt)
  local dir = activeItemAnimation.ownerFacingDirection()
  local rot = animationConfig.animationParameter("rotation") or 0
  local epos = activeItemAnimation.ownerPosition()
  local handPos = animationConfig.animationParameter "handPos"
  
  local frontArmAngle = aaa
  local backArmAngle = aaa
  
  local dm = {dir, 1}
  local fp = vec2.mul(vec2.sub(vec2.rotate(frontPivotOffset, frontArmAngle), frontPivotOffset), dm)
  local bp = vec2.mul(vec2.sub(vec2.rotate(backPivotOffset, backArmAngle), backPivotOffset), dm)
  
  local frontArmPos = vec2.add(epos, vec2.rotate(vec2.add(handPos, fp), rot))
  local backArmPos = vec2.add(epos, vec2.rotate(vec2.add(handPos, bp), rot))
  
  local armBase = animationConfig.animationParameter("armBase")
  local hideBase = animationConfig.animationParameter("hideBase")
  local sleeve = animationConfig.animationParameter("sleeve")
  
  local prop = {
    rotation = rot*dir + aaa,
    centered = true,
    mirrored = dir < 0,
    --position = frontArmPos,--vec2.add(activeItemAnimation.ownerPosition(), {2, 0}),
    zlevel = 0,
  }
  aaa = aaa + dt*0.75
  
  local armPose = {front = "rotation", back = "rotation"}
  
  localAnimator.clearDrawables()
  if not hideBase then
    localAnimator.addDrawable(util.mergeTable({ image = string.format(armBase.back, armPose.back), position = backArmPos }, prop), "Player-1")
    localAnimator.addDrawable(util.mergeTable({ image = string.format(armBase.front, armPose.front), position = frontArmPos }, prop), "Player")
  end
  if sleeve then
    localAnimator.addDrawable(util.mergeTable({ image = string.format(sleeve.back, armPose.back), position = backArmPos }, prop), "Player-1")
    localAnimator.addDrawable(util.mergeTable({ image = string.format(sleeve.front, armPose.front), position = frontArmPos }, prop), "Player")
  end
end
