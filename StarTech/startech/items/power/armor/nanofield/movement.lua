--

-- steal tweening from dynitem
require "/lib/stardust/dynitem.lua"
local tween = dynItem.tween
dynItem = nil

movement = { }

movement.prevVelocity = mcontroller.velocity()

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

--    --
-- -- --
--    --

do local s = movement.state("ground")
  function s:init()
    tech.setParentState()
    mcontroller.setRotation(0)
    mcontroller.clearControls()
    
    self.airJumps = 0
  end
  
  function s:uninit()
    
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
  
  function s:hardFall()
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
