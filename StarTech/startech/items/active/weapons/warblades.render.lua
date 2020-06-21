require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  --for k in pairs(activeItemAnimation) do sb.logInfo("activeItemAnimation."..k) end
  --for k in pairs(animationConfig) do sb.logInfo("animationConfig."..k) end
  entityId = animationConfig.animationParameter("entityId")
end

function update()
  local dir = activeItemAnimation.ownerFacingDirection()
  local rot = animationConfig.animationParameter("rotation")
  local frontArmPos = vec2.add(activeItemAnimation.ownerPosition(), vec2.rotate(animationConfig.animationParameter "handPos", -rot))
  --frontArmPos = vec2.add(activeItemAnimation.ownerPosition(), vec2.rotate(animationConfig.partPoint("root", "root"), -rot))
  
  local armBase = animationConfig.animationParameter("armBase")
  local hideBase = animationConfig.animationParameter("hideBase")
  local sleeve = animationConfig.animationParameter("sleeve")
  
  local prop = {
    --image = string.format(armBase.front, "rotation"),
    rotation = rot*dir,
    centered = true,
    mirrored = dir < 0,
    position = frontArmPos,--vec2.add(activeItemAnimation.ownerPosition(), {2, 0}),
    zlevel = -10000,
  }
  
  local armPose = {front = "rotation"}
  
  localAnimator.clearDrawables()
  if not hideBase then
    localAnimator.addDrawable(util.mergeTable({ image = string.format(armBase.front, armPose.front) }, prop), "player")
  end
  if sleeve then
    localAnimator.addDrawable(util.mergeTable({ image = string.format(sleeve.front, armPose.front) }, prop), "player")
  end
end
