require "/tech/distortionsphere/distortionsphere.lua"
require "/scripts/rect.lua"
require "/scripts/poly.lua"
require "/scripts/status.lua"

function init()
  initCommonParameters()

  self.ignorePlatforms = config.getParameter("ignorePlatforms")
  self.damageDisableTime = config.getParameter("damageDisableTime")
  self.damageDisableTimer = 0

  self.headingAngle = nil

  self.normalCollisionSet = {"Block", "Dynamic"}
  if self.ignorePlatforms then
    self.platformCollisionSet = self.normalCollisionSet
  else
    self.platformCollisionSet = {"Block", "Dynamic", "Platform"}
  end

  self.damageListener = damageListener("damageTaken", function(notifications)
    for _, notification in pairs(notifications) do
      if notification.healthLost > 0 and notification.sourceEntityId ~= entity.id() then
        damaged()
        return
      end
    end
  end)
end

function update(args)
  restoreStoredPosition()

  if not self.specialLast and args.moves["special"] == 1 then
    self.jumpTimer = 5
    attemptActivation()
  end
  self.specialLast = args.moves["special"] == 1

  self.damageDisableTimer = math.max(0, self.damageDisableTimer - args.dt)

  self.damageListener:update()
  
  local onGround

  if self.active then
    local groundDirection
    if self.damageDisableTimer == 0 then
      groundDirection = findGroundDirection()
    end
    
    
    
    if self.jumpTimer == nil then self.jumpTimer = 0 end
    if self.jumpTimer > 0 then self.jumpTimer = self.jumpTimer - 1 end
    -- jump!
    if groundDirection or mcontroller.groundMovement() then onGround = true end
    if onGround and not self.lastGround and self.jumpTimer == 0 then
      animator.setSoundVolume("spikeLock", 0.75, 0)
      animator.playSound("spikeLock")
      animator.setSoundVolume("spikeLock2", 2.0, 0)
      animator.playSound("spikeLock2")
    end
    if (args.moves["jump"] and not self.lastJump) and (groundDirection or mcontroller.groundMovement()) then
      if not groundDirection then groundDirection = {0, -1} end
      
      local jmpVec = vec2.mul(groundDirection, -25)
      local mv = 0
      if args.moves["right"] then mv = mv + 1 end
      if args.moves["left"] then mv = mv - 1 end
      jmpVec = vec2.add(jmpVec, vec2.mul(vec2.rotate(groundDirection, math.pi * 0.5), mv * 10))
      
      --jmpVec[2] = jmpVec[2] * 2
      if not args.moves["down"] then
        animator.playSound("spikeJump")
        animator.playSound("spikeJump2")
      else
        jmpVec[2] = 0
        jmpVec[1] = jmpVec[1] * 0.2
      end
      mcontroller.setVelocity(jmpVec)
      mcontroller.controlModifiers({airJumpModifier = 0})
      if jmpVec[2] > 0 then mcontroller.controlJump(true) end
      
      self.jumpTimer = 5
      --deactivate()
    end
    if self.jumpTimer > 0 then groundDirection = nil end

    if groundDirection then
      if not self.headingAngle then
        self.headingAngle = (math.atan(groundDirection[2], groundDirection[1]) + math.pi / 2) % (math.pi * 2)
      end

      local moveX = 0
      if args.moves["right"] then moveX = moveX + 1 end
      if args.moves["left"] then moveX = moveX - 1 end
      if moveX ~= 0 then
        -- find any collisions in the moving direction, and adjust heading angle *up* until there is no collision
        -- this makes the heading direction follow concave corners
        local adjustment = 0
        for a = 0, math.pi, math.pi / 4 do
          local testPos = vec2.add(mcontroller.position(), vec2.rotate({moveX * 0.25, 0}, self.headingAngle + (moveX * a)))
          adjustment = moveX * a
          if not world.polyCollision(poly.translate(poly.scale(mcontroller.collisionPoly(), 1.0), testPos), nil, self.normalCollisionSet) then
            break
          end
        end
        self.headingAngle = self.headingAngle + adjustment

        -- find empty space in the moving direction and adjust heading angle *down* until it collides
        -- adjust to the angle *before* the collision occurs
        -- this makes the heading direction follow convex corners
        adjustment = 0
        for a = 0, -math.pi, -math.pi / 4 do
          local testPos = vec2.add(mcontroller.position(), vec2.rotate({moveX * 0.25, 0}, self.headingAngle + (moveX * a)))
          if world.polyCollision(poly.translate(poly.scale(mcontroller.collisionPoly(), 1.0), testPos), nil, self.normalCollisionSet) then
            break
          end
          adjustment = moveX * a
        end
        self.headingAngle = self.headingAngle + adjustment

        -- apply a gravitation like force in the ground direction, while moving in the controlled direction
        -- Note: this ground force causes weird collision when moving up slopes, result is you move faster up slopes
        local groundAngle = self.headingAngle - (math.pi / 2)
        mcontroller.controlApproachVelocity(vec2.withAngle(groundAngle, self.ballSpeed), 300)
        
        local moveDirection = vec2.rotate({moveX, 0}, self.headingAngle)
        mcontroller.controlApproachVelocityAlongAngle(math.atan(moveDirection[2], moveDirection[1]), self.ballSpeed, 2000)

        self.angularVelocity = -moveX * self.ballSpeed
      else
        mcontroller.controlApproachVelocity({0,0}, 2000)
        self.angularVelocity = 0
      end

      mcontroller.controlDown()
      updateAngularVelocity(args.dt)

      self.transformedMovementParameters.gravityEnabled = false
    else
      updateAngularVelocity(args.dt)
      self.transformedMovementParameters.gravityEnabled = true
    end

    mcontroller.controlParameters(self.transformedMovementParameters)
    status.setResourcePercentage("energyRegenBlock", 1.0)

    updateRotationFrame(args.dt)
  else
    self.headingAngle = nil
  end

  updateTransformFade(args.dt)

  self.lastPosition = mcontroller.position()
  
  self.lastJump = args.moves["jump"]
  self.lastGround = onGround
end

function damaged()
  if self.active then
    self.damageDisableTimer = self.damageDisableTime
  end
end

function findGroundDirection()
  for i = 0, 3 do
    local angle = (i * math.pi / 2) - math.pi / 2
    local collisionSet = i == 1 and self.platformCollisionSet or self.normalCollisionSet
    local testPos = vec2.add(mcontroller.position(), vec2.withAngle(angle, 0.25))
    if world.polyCollision(poly.translate(mcontroller.collisionPoly(), testPos), nil, collisionSet) then
      return vec2.withAngle(angle, 1.0)
    end
  end
end
