--







function init()
  --self.energyCost = config.getParameter("energyCost", 10)
  --self.initialEnergyCost = config.getParameter("initialEnergyCost", self.energyCost)
  --self.drainBoost = 0
  
  self.surfaceEnergyCost = config.getParameter("surfaceEnergyCost", 1)
  self.zeroGEnergyCost = config.getParameter("zeroGEnergyCost", 1)
end

function update(args)
  local newJump = args.moves["jump"] and not self.lastJump
  self.lastJump = args.moves["jump"]
  --
  if mcontroller.zeroG() then -- rcs pack in space
    if args.moves["jump"] then
      local b = 25
      local bf = 25*1.5
      
      local vx = 0
      local vy = 0
      
      if args.moves["up"] then vy = vy + 1 end
      if args.moves["down"] then vy = vy - 1 end
      if args.moves["left"] then vx = vx - 1 end
      if args.moves["right"] then vx = vx + 1 end
      local sqrt2 = math.sqrt(2)
      if vx ~= 0 and vy ~= 0 then
        vx = vx / sqrt2
        vy = vy / sqrt2
      elseif vx == 0 and vy == 0 then
        bf = bf * 1.2 -- greater braking force
      end
      
      --mcontroller.addMomentum({vx*b, vy*b})
      if status.overConsumeResource("energy", self.zeroGEnergyCost * args.dt) then
        mcontroller.controlApproachVelocity({vx*b, vy*b}, bf * 60 * args.dt)
      end
    end
    
    self.jetpackActive = args.moves["jump"] -- set hover state for transition into gravity well
  else -- rocket boots effect a la Terraria in gravity
    --
    if mcontroller.onGround() or not args.moves["jump"] then
      self.jetpackActive = false
    elseif newJump then
      self.jetpackActive = true
    end
    
    if self.jetpackActive then
      if status.overConsumeResource("energy", self.surfaceEnergyCost * args.dt) then
        local bf = 300
        if mcontroller.yVelocity() < -5 then
          bf = bf * 1.2 -- greater boost force while canceling downwards momentum
        elseif args.moves["down"] then
          bf = bf * 0.0 -- hold down for pure braking
        end
        
        --local xv = mcontroller.xVelocity()
        --mcontroller.controlApproachVelocity({xv*0, 32}, bf * 60 * args.dt)
        --mcontroller.setXVelocity({xv, 0}) -- restore to eliminate weirdness
        if mcontroller.yVelocity() < 32 then mcontroller.addMomentum({0, bf * 1 * args.dt}) end
      else self.jetpackActive = false end
    end
  end
  
  animator.setParticleEmitterActive("rocketParticles", self.jetpackActive or false)
  animator.setFlipped(mcontroller.facingDirection() < 0)
  
end

-- TODO: "heat" measure affecting surface boost cost; rebalance costs in general

function applyFX(dt, onHealth)
  local blinkSpeed = 1.0
  local color = {0x00, 0x7f, 0xff, 0xff} -- "008fffff"
  if onHealth then
    local healthPercent = status.resourcePercentage("health")
    color = {0xff, 0x00, 0x00, 0xff} -- "ff0000ff"
    if healthPercent <= 2.0/15.0 then color = {0xff, 0xff, 0xff, 0xff} end -- "ffffffff"
    blinkSpeed = 1.0 - healthPercent
    blinkSpeed = blinkSpeed * blinkSpeed * blinkSpeed
    blinkSpeed = 1.0 + blinkSpeed * 5
  end
  
  self.blinkTimer = self.blinkTimer + dt * blinkSpeed
  
  local blink = 0.5 + math.sin(math.pi * 2.0 * self.blinkTimer) * 0.5
  animator.setLightColor("hyper", colorMult(color, 0.1 + blink * 0.4))
  
  tech.setParentDirectives("?fade=" .. colorToString(color) .. "=" .. (blink * 0.32))
end

function tryActivate()
  if self.active then deactivate() else activate() end
end

function activate()
  -- fail if no energy
  if not status.overConsumeResource("energy", self.initialEnergyCost) then return end
  self.active = true
  self.blinkTimer = 0
end

function deactivate()
  self.active = false
end

function colorMult(color, mult)
  return { color[1] * mult, color[2] * mult, color[3] * mult, color[4] * mult }
end
function colorToString(color)
  return string.format("%x", color[1] * 16777216 + color[2] * 65536 + color[3] * 256 + color[4])
end
