--

-- steal tweening from dynitem
require "/lib/stardust/dynitem.lua"
local tween = dynItem.tween
dynItem = nil

movement = { }

movement.prevVelocity = mcontroller.velocity()

local function towards(cur, target, max)
  max = math.abs(max)
  if max == 0 then return cur end
  if target == cur then return target end
  local diff = target - cur
  local sign = diff / math.abs(diff)
  return cur + math.min(math.abs(diff), max) * sign
end
local rotTowards = towards -- just an alias for now

do -- core private
  local cr, st
  local states = { }
  
  function movement.update(p)
    movement.zeroGPrev = movement.zeroG
    movement.zeroG = (world.gravity(mcontroller.position()) == 0) or status.statusProperty("fu_byosnogravity", false)
    
    if not st or not cr or coroutine.status(cr) == "dead" then movement.switchState("ground") end
    local f, err = coroutine.resume(cr)
    if not f then sb.logError(err) end
    
    movement.prevVelocity = mcontroller.velocity()
  end
  
  function movement.state(name)
    if not states[name] then states[name] = { } end
    return states[name]
  end
  
  function movement.switchState(name, ...)
    if not states[name] then return nil end
    local par = {...}
    local ocr, ost = cr, st
    cr, st = nil -- preclear
    
    local nst = setmetatable({ }, { __index = states[name] })
    st = nst -- this is a separate variable for capture purposes
    
    cr = coroutine.create(function()
      -- get state changes out of the way
      if ost and ost.uninit then ost:uninit() end
      if nst.init then nst:init(table.unpack(par)) end
      local r = { }
      while true do
        if r[1] then
          r = { r[1](nst, table.unpack(r, 2)) }
        else
          r = { (nst.main or coroutine.yield)(nst) }
        end
      end
    end)
    
    if coroutine.running() == ocr then
      local f, err = coroutine.resume(cr)
      if not f then sb.logError(err) end
      coroutine.yield()
    end
  end
  
  function movement.call(fn, ...) if st and type(st[fn]) == "function" then return st[fn](st, ...) end end
end

---     ---
--- --- ---
---     ---

do local s = movement.state("ground")
  function s:init()
    tech.setParentState()
    mcontroller.setRotation(0)
    mcontroller.clearControls()
    
    self.airJumps = 0
  end
  
  function s:uninit()
    
  end
  
  function s:onHardFall()
    movement.switchState("hardFall")
  end
  
  function s:main()
    --
    tech.setParentState() -- default to no state override
    
    if mcontroller.groundMovement() then self.airJumps = 1 end
    
    if input.keyDown.t1 then
      input.keyDown.t1 = false -- consume press
      if input.key.down and not zeroG then
        movement.switchState("sphere")
      else
        movement.switchState("flight", true)
      end
    end
    if input.key.sprint then -- sprint instead of slow walk!
      local v = input.dir[1]
      if v ~= 0 then
        --mcontroller.controlApproachXVelocity(255 * v, 255)
        mcontroller.controlMove(v, true)
        mcontroller.controlModifiers({ speedModifier = 1.75 })
        --tech.setParentState("running")
      end
      if input.keyDown.jump and mcontroller.onGround() then -- slight bunnyhop effect
        mcontroller.setXVelocity(mcontroller.velocity()[1] * 1.5)
      end
    end
    
    -- air jump, borrowed from Aetheri
    if not mcontroller.canJump()
    and not mcontroller.jumping()
    and not mcontroller.liquidMovement()
    --and mcontroller.yVelocity() < 0
    and input.keyDown.jump and self.airJumps >= 1 then
      self.airJumps = self.airJumps - 1
      mcontroller.controlJump(true)
      mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
      mcontroller.controlParameters({ airForce = 1750.0 }) -- allow easier direction control during jump
      sound.play("/sfx/tech/tech_doublejump.ogg")
      tech.setParentState("Fall") -- animate a bit even when already rising
    end
    
    if movement.zeroG and not movement.zeroGPrev then movement.switchState("flight") end
    
    coroutine.yield()
  end
end

--- --- ---

do local s = movement.state("hardFall")
  function s:init()
    self.time = 0
    self.startingVelocity = movement.prevVelocity[1]
  end

  function s:uninit()
    mcontroller.clearControls()
    tech.setParentState()
  end

  function s:main()
    mcontroller.controlModifiers({ speedModifier = 0, normalGroundFriction = 0, ambulatingGroundFriction = 0 }) -- just a tiny bit of slide
    mcontroller.setXVelocity(prevVelocity[1] * (1.0 - 5.0 * p.dt))
    tech.setParentState("duck")
    for v in tween(0.333) do
      if not mcontroller.onGround() then break end
      if input.keyDown.jump then
        mcontroller.controlJump(5)
        mcontroller.setVelocity({self.startingVelocity * 2.5, -5})
        break
      end
    end
    movement.switch("ground")
  end
end

--- --- ---

do local s = movement.state("sphere")
  function s:init()
    self.collisionPoly = { {-0.85, -0.45}, {-0.45, -0.85}, {0.45, -0.85}, {0.85, -0.45}, {0.85, 0.45}, {0.45, 0.85}, {-0.45, 0.85}, {-0.85, 0.45} }
    mcontroller.controlParameters({ collisionPoly = self.collisionPoly })
    mcontroller.setYPosition(mcontroller.position()[2]-(29/16))
    
    tech.setToolUsageSuppressed(true)
    tech.setParentHidden(true)
    self.ball = Prop.new(0)
    self.ball:setImage("/tech/distortionsphere/distortionsphere.png", "/tech/distortionsphere/distortionsphereglow.png")
    self.ball:setFrame(0)
    self.rot = 0.5
    sound.play("/sfx/tech/tech_sphere_transform.ogg")
  end

  function s:uninit()
    self.ball:discard()
    tech.setParentHidden(false)
    tech.setToolUsageSuppressed(false)
    sound.play("/sfx/tech/tech_sphere_transform.ogg")
    mcontroller.setYPosition(mcontroller.position()[2]+(29/16))
    mcontroller.clearControls()
  end
  
  function s:onHardFall()
    mcontroller.setXVelocity(prevVelocity[1] * 2)
  end

  function s:main()
    sb.logInfo("sphere main")
    if input.keyDown.t1 then -- unmorph
      input.keyDown.t1 = false -- consume press
      movement.switchState(movement.zeroG and "flight" or "ground")
    end
    mcontroller.clearControls()
    mcontroller.controlParameters({
      collisionPoly = self.collisionPoly,
      groundForce = 450,
      runSpeed = 25, walkSpeed = 25,
      normalGroundFriction = 0.75,
      ambulatingGroundFriction = 0.2,
      slopeSlidingFactor = 3.0,
    })
    self.rot = self.rot + mcontroller.xVelocity() * script.updateDt() * -2.0
    while self.rot < 0 do self.rot = self.rot + 8 end
    while self.rot >= 8 do self.rot = self.rot - 8 end
    self.ball:setFrame(math.floor(self.rot))
    
    coroutine.yield()
  end

end

--- --- ---

do local s = movement.state("flight")
  
  local wingDefaults = {
    energyColor = "ff0354",
    baseRotation = 0.0,
    soundActivate = "/sfx/objects/ancientlightplatform_on.ogg",
    soundDeactivate = "/sfx/objects/ancientlightplatform_off.ogg",
    soundThrust = "/sfx/npc/boss/kluexboss_vortex_windy.ogg",--"/sfx/objects/steel_elevator_loop.ogg",--"/sfx/tech/tech_sonicsphere_charge1.ogg",
    soundThrustVolume = 1.0,
    soundThrustPitch = 1.0,
    soundThrustBoostPitch = 1.22,
  }
  --[[ testing: Poptra
  wingDefaults.baseRotation = 0.3
  wingDefaults.soundThrust = "nyan.ogg"
  wingDefaults.soundThrustVolume = 0.45
  wingDefaults.soundThrustPitch = 0.9
  wingDefaults.soundThrustBoostPitch = 1.0
  --]]
  
  function s:init(summoned)
    self.hEff = 0
    self.vEff = 0
    
    self.stats = wingDefaults
    
    if summoned then
      self.summoned = true
      if mcontroller.groundMovement() then -- lift off ground a bit
        mcontroller.setYVelocity(12)
      end
    end
    
    appearance.setWings(self.stats)
    appearance.setWingsVisible(true)
    sound.play(self.stats.soundActivate)
    self.thrustLoop = sound.newLoop(self.stats.soundThrust)
    
    -- temporarily kill problematic FR effects
    status.removeEphemeralEffect("swimboost2")
  end
  
  function s:uninit()
    tech.setParentState()
    mcontroller.setRotation(0)
    mcontroller.clearControls()
    
    appearance.setWingsVisible(false)
    self.thrustLoop:discard()
    sound.play(self.stats.soundDeactivate)
    
    -- restore FR effects
    world.sendEntityMessage(entity.id(), "playerext:reinstateFRStatus")
  end
  
  function s:updateEffectiveStats(sg)
    util.appendLists(sg, {
      -- glide effortlessly through most FU gases
      { stat = "gasImmunity", amount = 1.0 },
      { stat = "helium3Immunity", amount = 1.0 },
    })
  end
  
  -- couple functions from Aetheri
  local setPose = coroutine.wrap(function()
    local threshold = 1/6
    local t = 0.0
    local f = false
    while true do
      local a = ((vec2.mag(input.dirN) ~= 0 and vec2.dot(input.dirN, vec2.norm(mcontroller.velocity())) > 0) and 1.0 or -1.0) * script.updateDt()
      t = util.clamp(t + a/threshold, 0.0, 1.0)
      if t == 1.0 then f = true elseif t == 0.0 then f = false end
      if f then tech.setParentState("fly") else tech.setParentState() end
      coroutine.yield()
    end
  end)
  
  local function forceFacing(f)
    mcontroller.controlModifiers{movementSuppressed = false}
    mcontroller.controlFace(f)
    mcontroller.controlModifiers{movementSuppressed = true}
  end
  
  function s:main()
    mcontroller.clearControls()
    mcontroller.controlParameters{
      gravityEnabled = false,
      frictionEnabled = false,
      liquidImpedance = -100, -- full speed in water
      liquidBuoyancy = -1000, -- same as above
      groundForce = 0, airForce = 0, liquidForce = 0, -- disable default movement entirely
      maximumPlatformCorrection = 0.0,
      maximumPlatformCorrectionVelocityFactor = 0.0,
    }
    mcontroller.controlModifiers{ movementSuppressed = true } -- disable harder, and also don't paddle at the air
    if input.keyDown.t1 then
      input.keyDown.t1 = false -- consume press
      movement.switchState("ground")
    end
    
    local dt = script.updateDt()
    
    local curSpeed = vec2.mag(mcontroller.velocity())
    local boost = input.key.sprint and 55 or 25
    
    if input.dir[1] ~= 0 then forceFacing(input.dir[1]) end
    
    -- for now this is just taken straight from the Aetheri
    local forceMult = util.lerp((1.0 - vec2.dot(input.dirN, vec2.norm(mcontroller.velocity()))) * 0.5, 0.5, 1.0)
    if vec2.mag(input.dirN) < 0.25 then forceMult = 0.25 end
    mcontroller.controlApproachVelocity(vec2.mul(input.dirN, boost), 12500 * forceMult * dt)
    
    setPose()
    self.hEff = towards(self.hEff, util.clamp(mcontroller.velocity()[1] / 55, -1.0, 1.0), dt * 8)
    self.vEff = towards(self.vEff, util.clamp(mcontroller.velocity()[2] / 55, -1.0, 1.0), dt * 8)
    --local rot = util.clamp(mcontroller.velocity()[1] / -55, -1.0, 1.0)
    local rot = math.sin(self.hEff * -1 * math.pi * .45) / (.45*2)
    local targetRot = rot * math.pi * .09
    mcontroller.setRotation(rotTowards(mcontroller.rotation(), targetRot, math.pi * .09 * 8 * dt))
    
    local rot2 = self.hEff * -1 * mcontroller.facingDirection()
    if rot2 < 0 then -- less extra rotation when moving forwards
      rot2 = rot2 * 0.32
    else -- and a wing flare
      rot2 = rot2 * 1.7
    end
    rot2 = rot2 + self.vEff * 0.75
    
    -- sound
    self.thrustLoop:setVolume(self.stats.soundThrustVolume * util.clamp(vec2.mag(mcontroller.velocity()) / 20, 0.0, 1.0))
    local pitch = vec2.mag(mcontroller.velocity())
    if pitch <= 25 then
      pitch = util.lerp(util.clamp(pitch / 20, 0.0, self.stats.soundThrustPitch), 0.25, 1.0)
    else
      pitch = util.lerp(util.clamp((pitch - 25) / (45-25), 0.0, 1.0), self.stats.soundThrustPitch, self.stats.soundThrustBoostPitch)
    end
    self.thrustLoop:setPitch(pitch)
    
    appearance.positionWings(rot2)
    
    if not zeroG and zeroGPrev then movement.switchState("ground") end
    
    coroutine.yield()
  end
end
