--

movement = {
  states = { },
}
local currentState = { } -- internal
local stateData = { } -- stuff

function movement.enterState(id, ...)
  if currentState == movement.states[id] or not movement.states[id] then return nil end
  movement.callState("uninit", id)
  local prevState = currentState
  local prevStateData = stateData
  currentState = movement.states[id]
  stateData = { }
  movement.callState("init", prevState, prevStateData, ...)
end

function movement.callState(f, ...)
  if currentState[f] then return currentState[f](stateData, ...) end
end

function movement.update(p)
  movement.callState("update", p.dt) -- don't need to pass in p since input module exists
end

-- for now, states are just part of the movement module; this may change... eventually

movement.states.ground = { }
function movement.states.ground:init()
  self.airJumps = 0
end

function movement.states.ground:uninit()
  --
end

function movement.states.ground:update(dt)
  if mcontroller.onGround() then
    self.sprinting = input.key.sprint and input.dir[1] ~= 0
    self.airJumps = stats.stat.airJumps
  end
  if self.sprinting then
    mcontroller.controlMove(input.dir[1], true) -- set running
    -- sprint speed and a bit of a jump boost
    mcontroller.controlModifiers({ speedModifier = 1.5, airJumpModifier = 1.35 })
  end
  
  -- air jump!
  if not mcontroller.canJump()
  and not mcontroller.jumping()
  and not mcontroller.liquidMovement()
  --and mcontroller.yVelocity() < 0
  and input.keyDown.jump and self.airJumps >= 1 then
    self.airJumps = self.airJumps - 1
    mcontroller.controlJump(true)
    mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
    mcontroller.controlParameters({ airForce = 1750.0 }) -- allow easier direction control during jump
    self.sprinting = self.sprinting or (input.key.sprint and input.dir[1] ~= 0) -- allow starting a sprint from an air jump
    sound.play("/sfx/tech/tech_doublejump.ogg")
    -- TODO: particle/animation stuff
  end
end
