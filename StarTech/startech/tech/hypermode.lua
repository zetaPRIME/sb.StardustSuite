--







function init()
  self.energyCost = config.getParameter("energyCost", 10)
  self.initialEnergyCost = config.getParameter("initialEnergyCost", self.energyCost)
  self.drainBoost = 0
end

function update(args)
  --
  if not self.specialLast and args.moves["special"] == 1 then
    tryActivate()
  end
  self.specialLast = args.moves["special"] == 1
  
  if self.active then
    local onHealth = false
    
    -- consume energy
    if self.energyDepleted or not status.overConsumeResource("energy", self.energyCost * args.dt) then
      self.drainBoost = math.max(self.drainBoost - args.dt, 0)
      local lifeDrainRate = 1.0 + self.drainBoost * 0.5
      if status.resource("health") < 0.01 then -- energy overuse speeds up health drain
        self.drainBoost = 2.5
      end
      -- keep draining from life
      status.overConsumeResource("health", self.energyCost * args.dt * lifeDrainRate)
      --status.modifyResource("energy", 5730) -- try force-recharge
      status.setResource("energy", 0.01)
      status.setResourceLocked("energy", false)
      
      onHealth = true
      self.energyDepleted = true
    end
    
    -- boost stats
    status.setPersistentEffects("hypermode", {
      { stat = "fallDamageMultiplier", effectiveMultiplier = 0.0 },
      { stat = "protection", effectiveMultiplier = 3.0 }, --amount = 10 },
      { stat = "powerMultiplier", effectiveMultiplier = 3.0 },
      
      --{ stat = "energyRegenBlockTime", effectiveMultiplier = 0 },
      
      { stat = "dummy", amount = 0 } -- dummy cap
    })
    
    -- and movement
    mcontroller.controlModifiers({
      speedModifier = 2.0,
      airJumpModifier = 1.5
    })
    
    -- and apply visuals
    applyFX(args.dt, onHealth)
  
  else
    status.clearPersistentEffects("hypermode")
    tech.setParentDirectives("") -- blank out
    self.energyDepleted = false
    self.drainBoost = 0
  end
  
  animator.setLightActive("hyper", self.active)
  
end

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
