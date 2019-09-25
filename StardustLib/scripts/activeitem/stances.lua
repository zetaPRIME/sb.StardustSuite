require "/scripts/util.lua"
require "/scripts/vec2.lua"

function initStances()
  self.stances = config.getParameter("stances")
  self.fireOffset = config.getParameter("fireOffset", {0, 0})
  self.fireAngleOffset = util.toRadians(config.getParameter("fireAngleOffset", 0))
  self.aimAngle = 0
  
  if root.hasTech("stardustlib:enable-extenders") then -- stardustlib shim
    require "/sys/stardust/weaponext.lua"
  end
end

function setStance(stanceName)
  self.stanceName = stanceName
  self.stance = self.stances[stanceName]
  self.stanceTimer = self.stance.duration
  for part, state in pairs(self.stance.animationState or {}) do
    animator.setAnimationState(part, state)
  end
  for group, transform in pairs(self.stance.transformations or {}) do
    animator.resetTransformationGroup(group)
    if transform.translate then animator.translateTransformationGroup(group, transform.translate) end
    if transform.rotate then animator.rotateTransformationGroup(group, util.toRadians(transform.rotate)) end
    if transform.scale then animator.scaleTransformationGroup(group, transform.scale) end
  end
  if type(self.stance.armRotation) == "table" then
    self.armRotation = self.stance.armRotation[1]
  else
    self.armRotation = self.stance.armRotation or 0
  end
  if self.stance.resetAim then
    self.aimAngle = 0
  end
  activeItem.setTwoHandedGrip(self.stance.twoHanded or false)
  updateAim(self.stance.allowRotate, self.stance.allowFlip)
end

function updateStance(dt)
  if self.stanceTimer then
    self.stanceTimer = math.max(self.stanceTimer - dt, 0)

    if type(self.stance.armRotation) == "table" then
      local stanceRatio = 1 - (self.stanceTimer / self.stance.duration)
      self.armRotation = util.lerp(stanceRatio, self.stance.armRotation)
    end

    if self.stanceTimer <= 0 then
      local transitionFunction = self.stance.transitionFunction
      if self.stance.transition then
        setStance(self.stance.transition)
      end
      if transitionFunction then
        _ENV[transitionFunction]()
      end
    end
  end
end

function updateAim(allowRotate, allowFlip)
  allowRotate = allowRotate or self.stance.allowRotate
  allowFlip = allowFlip or self.stance.allowFlip

  local aimAngle, aimDirection = activeItem.aimAngleAndDirection(self.fireOffset[2], activeItem.ownerAimPosition())

  if allowRotate then
    self.aimAngle = aimAngle
  end
  aimAngle = self.aimAngle + util.toRadians(self.armRotation)
  self.armAngle = aimAngle
  activeItem.setArmAngle(aimAngle)

  if allowFlip then
    self.aimDirection = aimDirection
  end
  activeItem.setFacingDirection((self.aimDirection or 0))
end

function firePosition()
  return vec2.add(mcontroller.position(), activeItem.handPosition(self.fireOffset))
end

function aimVector()
  local aimVector = vec2.rotate({1, 0}, self.aimAngle + self.fireAngleOffset)
  aimVector[1] = aimVector[1] * self.aimDirection
  return aimVector
end
