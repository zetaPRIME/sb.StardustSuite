function init()
  self.multiJumpCount = config.getParameter("multiJumpCount")
  self.multiJumpModifier = config.getParameter("multiJumpModifier")

  refreshJumps()
end

function update(args)
  local jumpActivated = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]

  updateJumpModifier()

  if jumpActivated and canMultiJump() then
    doMultiJump(args.moves)
  else
    if mcontroller.groundMovement() or mcontroller.liquidMovement() then
      refreshJumps()
    end
  end
end

-- after the original ground jump has finished, start applying the new jump modifier
function updateJumpModifier()
  -- putting this here to make sure it triggers in all "subclasses"
  if self.burstCooldown == nil then self.burstCooldown = 0 end
  if self.burstCooldown > 0 then self.burstCooldown = self.burstCooldown - 1 end
  
  if self.multiJumpModifier then
    if not self.applyJumpModifier
        and not mcontroller.jumping()
        and not mcontroller.groundMovement() then

      self.applyJumpModifier = true
    end

    if self.applyJumpModifier then mcontroller.controlModifiers({airJumpModifier = self.multiJumpModifier}) end
  end
end

function canMultiJump(fromJump)
  if not fromJump then return true end -- let's see...
  
  return self.multiJumps > 0
      and not mcontroller.jumping()
      and not mcontroller.canJump()
      and not mcontroller.liquidMovement()
      and not status.statPositive("activeMovementAbilities")
end

function doMultiJump(moves)
  local cooldown = 40
  
  if moves["down"] then
    if self.burstCooldown > 0 then return end
    self.burstCooldown = cooldown
  else
    if not canMultiJump(true) then return end
    self.multiJumps = self.multiJumps - 1
    self.burstCooldown = cooldown
  end
  
  mcontroller.controlJump(true)
  mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
  -- self.multiJumps = self.multiJumps - 1
  animator.burstParticleEmitter("multiJumpParticles")
  animator.playSound("multiJumpSound")
end

function refreshJumps()
  self.multiJumps = self.multiJumpCount
  self.applyJumpModifier = false
end
