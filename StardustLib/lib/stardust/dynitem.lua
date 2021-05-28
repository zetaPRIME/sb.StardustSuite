-- StardustLib.dynItem

require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/lib/stardust/weaponutil.lua"

do
  dynItem = { }
  local queue = { }
  
  dynItem.aimOffset = {0, 0}
  dynItem.aimVOffset = 0
  dynItem.time = 0
  
  dynItem.autoResetRegions = true
  
  local function updateAim()
    do
      activeItem.setArmAngle(0)
      local p1 = activeItem.handPosition()
      activeItem.setArmAngle(math.pi)
      local p2 = activeItem.handPosition()
      dynItem.shoulderPos = vec2.mul(vec2.add(p1, p2), 0.5)
    end
    
    dynItem.aimPos = vec2.add(vec2.add(activeItem.ownerAimPosition(), vec2.mul(mcontroller.velocity(), script.updateDt())), dynItem.aimOffset)
    dynItem.aimAngle, dynItem.aimDir = activeItem.aimAngleAndDirection(dynItem.aimVOffset, dynItem.aimPos)
    if dynItem.autoAim then dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle) -- aim at cursor
    else dynItem.aimAt(dynItem.dir, dynItem.armAngle) end -- hold previous angle
    if dynAnim then activeItem.setArmAngle(0) end -- undo interference
  end
  
  function dynItem.aimAt(dir, angle)
    dynItem.dir, dynItem.armAngle = dir, angle
    dir = dir or mcontroller.facingDirection()
    angle = angle or 0
    activeItem.setFacingDirection(dir)
    activeItem.setArmAngle(angle - mcontroller.rotation() * dir)
  end
  
  function dynItem.aimAtPos(vec, dir)
    local aimPos = vec2.add(vec2.add(vec, vec2.mul(mcontroller.velocity(), script.updateDt())), dynItem.aimOffset)
    local aimAngle, aimDir = activeItem.aimAngleAndDirection(dynItem.aimVOffset, aimPos)
    if dir then
      if dir ~= aimDir then aimAngle = -aimAngle + math.pi end
      aimDir = dir
    end
    dynItem.aimAt(aimDir, aimAngle)
  end
  
  function dynItem.setAutoAim(f)
    if mcontroller then -- adjust immediately if already init'd
      if f and not dynItem.autoAim then dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle) end
      --elseif dynItem.autoAim and not f then dynItem.aimAt(dynItem.dir, 0) end
    end
    dynItem.autoAim = f
  end
  
  function dynItem.aimVector(dir, angle, mag)
    dir, angle, mag = dir or dynItem.aimDir, angle or dynItem.aimAngle, mag or 1.0
    return vec2.rotate({dir*mag, 0}, dir*angle)
  end
  
  local impulseMaxVelocity = 100
  function dynItem.impulse(v, velMult, raw)
    velMult = velMult or 0
    if type(v) == "number" then v = dynItem.aimVector(nil, nil, v) end
    if mcontroller.groundMovement() then v = vec2.add(v, {0, 5}) end -- bit of help to lift
    if velMult == 0 then
      return weaponUtil.impulse(v, raw)
    else
      local vel = mcontroller.velocity()
      local p = math.max(0, vec2.dot(vec2.norm(vel), vec2.norm(v)))
      local fVel = vec2.mul(vel, p * velMult)
      if vec2.mag(fVel) > impulseMaxVelocity then -- restrain added impulse to maximum value
        fVel = vec2.mul(vec2.norm(fVel), impulseMaxVelocity)
      end
      return weaponUtil.impulse(vec2.add(v, fVel), raw)
    end
  end
  
  function dynItem.offsetPoly(p, fromShoulder, angle)
    local r = { }
    local rot, scale = angle or dynItem.armAngle, {mcontroller.facingDirection(), 1}
    local hp = vec2.rotate(fromShoulder and dynItem.shoulderPos or activeItem.handPosition(), mcontroller.rotation())
    for _, pt in pairs(p) do
      table.insert(r, vec2.add(vec2.mul( vec2.rotate(pt, rot), scale), hp))
    end
    return r
  end
  
  function dynItem.normalizeTransformationGroup(g)
    --animator.resetTransformationGroup(g)
    local d, r = mcontroller.facingDirection(), mcontroller.rotation()
    animator.translateTransformationGroup(g, vec2.mul(vec2.rotate(activeItem.handPosition(), r), {-1, -1}))
    animator.translateTransformationGroup(g, vec2.rotate(dynItem.shoulderPos, r))
    animator.rotateTransformationGroup(g, -dynItem.armAngle * d)
    animator.scaleTransformationGroup(g, {d, 1})
  end
  
  function dynItem.tween(v1, v2, time)
    if not v2 and not time then
      time = v1
      v1, v2 = 0.0, 1.0
    end
    local c = coroutine.create(function()
      local t = 0
      while t < 1.0 do
        coroutine.yield(util.lerp(t, v1, v2))
        t = t + script.updateDt() / time
      end
      return v2
    end)
    local first = true
    return function()
      if coroutine.status(c) == "dead" then return nil end
      local fst = first
      if first then first = false else coroutine.yield() end
      local f, v = coroutine.resume(c)
      if not f then sb.logError(v) return nil end
      return v, fst
    end
  end
  
  function dynItem.addTask(f) table.insert(queue, coroutine.create(f)) end
  
  local buffered, bufferedAlt, held, heldAlt = false, false, false, false
  function dynItem.startBuffer()
    buffered = dynItem.firePress
    bufferedAlt = dynItem.altFirePress
    held = dynItem.fire
    heldAlt = dynItem.altFire
  end
  function dynItem.buffered(alt)
    if alt then return bufferedAlt end
    return buffered
  end
  function dynItem.held(alt)
    if alt then return heldAlt end
    return held
  end
    
  
  function dynItem.update(dt, fireMode, shiftHeld)
    dynItem.time = dynItem.time + dt
    
    do -- handle input
      dynItem.shift = shiftHeld
      local f, af = fireMode == "primary", fireMode == "alt"
      dynItem.firePress, dynItem.altFirePress = f and not dynItem.fire, af and not dynItem.altFire
      dynItem.fire, dynItem.altFire = f, af
      
      -- handle buffering
      buffered = buffered or dynItem.firePress
      bufferedAlt = bufferedAlt or dynItem.altFirePress
      held = held and dynItem.fire
      heldAlt = heldAlt and dynItem.altFire
    end
    
    if dynItem.autoResetRegions then
      activeItem.setDamageSources()
      activeItem.setItemDamageSources()
      activeItem.setShieldPolys()
      activeItem.setItemShieldPolys()
      activeItem.setForceRegions()
      activeItem.setItemForceRegions()
    end
    
    updateAim()
    
    -- execute all queued coroutines
    local next = { }
    local reindex = false;
    for _, v in pairs(queue) do
      local f, err = coroutine.resume(v)
      if coroutine.status(v) ~= "dead" then table.insert(next, v) -- execute; insert in next-frame queue if still running
      elseif not f then sb.logError(err) end
    end
    queue = next
    
    if dynAnim then dynAnim.update(dt) end
  end
  
  function dynItem.install()
    if type(update) == "function" then -- preserve as first task per frame
      local u = update
      table.insert(queue, 1, coroutine.create(function() while true do u() coroutine.yield() end end))
    end
    update = dynItem.update
  end
  
  -- Combo system
  
  local function comboSystemLoop(df, ...)
    local r = { }
    while true do
      if r[1] then
        r = { r[1](table.unpack(r, 2)) }
      else
        r = { df(...) }
      end
    end
  end
  
  function dynItem.comboSystem(startingFunc, ...)
    local p = {...}
    dynItem.addTask(function() comboSystemLoop(startingFunc, table.unpack(p)) end)
    return dynItem -- chain
  end
  
end
