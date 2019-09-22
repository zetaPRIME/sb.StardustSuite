-- StardustLib.dynItem

require "/scripts/util.lua"
require "/scripts/vec2.lua"


do
  dynItem = { }
  local queue = { }
  
  dynItem.aimOffset = {0, 0}
  dynItem.aimVOffset = 0
  dynItem.time = 0
  
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
  
  function dynItem.offsetPoly(p, fromShoulder)
    local r = { }
    local rot, scale = dynItem.armAngle, {mcontroller.facingDirection(), 1}
    local hp = vec2.rotate(fromShoulder and dynItem.shoulderPos or activeItem.handPosition(), mcontroller.rotation())
    for _, pt in pairs(p) do
      table.insert(r, vec2.add(vec2.mul( vec2.rotate(pt, rot), scale), hp))
    end
    return r
  end
  
  function dynItem.normalizeTransformationGroup(g)
    --animator.resetTransformationGroup(g)
    local d = mcontroller.facingDirection()
    animator.translateTransformationGroup(g, vec2.mul(vec2.rotate(activeItem.handPosition(), mcontroller.rotation()), {-1, -1}))
    animator.translateTransformationGroup(g, dynItem.shoulderPos)
    animator.rotateTransformationGroup(g, -dynItem.armAngle * d)
    animator.scaleTransformationGroup(g, {d, 1})
  end
  
  function dynItem.tween(v1, v2, time)
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
  
  function dynItem.update(dt, fireMode, shiftHeld)
    dynItem.time = dynItem.time + dt
    
    do -- handle input
      dynItem.shift = shiftHeld
      local f, af = fireMode == "primary", fireMode == "alt"
      dynItem.firePress, dynItem.altFirePress = f and not dynItem.fire, af and not dynItem.altFire
      dynItem.fire, dynItem.altFire = f, af
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
