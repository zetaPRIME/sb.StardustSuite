require "/lib/stardust/dynitemanim.lua"
require "/startech/items/active/weapons/pulseweapon.lua"

function init() initPulseWeapon()
  --
end

function uninit()
  if status.statPositive "stardustlib:customFlying" then
    local t = 0.3
    mcontroller.setRotation(math.max(-t, math.min(t, mcontroller.rotation())))
  else mcontroller.setRotation(0) end
end


dynItem.install()
dynItem.setAutoAim(false)

function strike(dmg, type, poly, kb)
  --kb = kb or 1.0
  local np = #poly
  activeItem.setDamageSources { {
    poly = (np > 2) and poly or nil,
    line = (np == 2) and poly or nil,
    damage = damage(dmg),
    team = activeItem.ownerTeam(),
    damageSourceKind = type,
    statusEffects = weaponUtil.imbue {
      baseStatus(),
      kb or dynItem.impulse(25, 0.64),
    },
    --knockback = {0, 0},
    rayCheck = true,
    damageRepeatTimeout = 0,
  } }
end

function polyFan(width, rad, pts)
  local p = {{0, 0}}
  pts = pts or 7
  for i = 1, pts do
    table.insert(p, vec2.rotate({rad, 0}, (2 * ((i-1)/(pts-1)) - 1) * width))
  end
  return p
end

function idle()
  activeItem.setCursor()
  while true do
    dynItem.aimAt(dynItem.aimDir, 0)
    activeItem.setHoldingItem(false)
    
    if dynItem.firePress then dynItem.firePress = false return punch1 end
    if dynItem.altFirePress then dynItem.altFirePress = false return sweepKick end -- for now just skip to the finisher
    coroutine.yield()
  end
end dynItem.comboSystem(idle)

local function setIdleStance()
  dynAnim.setArmStates("in")
  dynAnim.setArmAngles(math.pi * 2/8)
  activeItem.setHoldingItem(true)
end

function punch1()
  local time = 0.25
  setIdleStance()
  dynItem.startBuffer()
  
  --for v in dynItem.tween(time*0.25) do end
  dynAnim.setFrontArmState "mid"
  dynAnim.setArmAngles(0, math.pi * -4/8)
  for v in dynItem.tween(time*0.1) do end
  mcontroller.addMomentum {dynItem.dir * 25, 0}
  dynAnim.setFrontArmState "out"
  dynAnim.setArmAngles(math.pi * 0.25/8, math.pi * -2/8)
  strike(time, dmgtype "fist", dynItem.offsetPoly(polyFan(math.pi * 2/8, 5), true, 0), dynItem.impulse({5*dynItem.dir, 3}, 0.64))
  for v in dynItem.tween(time*0.4) do end
  dynAnim.setFrontArmState "mid"
  dynAnim.setArmAngles(0, math.pi * -4/8)
  for v in dynItem.tween(time*0.1) do end
  setIdleStance()
  for v in dynItem.tween(time*0.4) do end
  --for v in dynItem.tween(time*0.6) do end
  
  if dynItem.buffered() then return punch2 end
end

function punch2()
  local time = 0.25
  setIdleStance()
  dynItem.startBuffer()
  
  --for v in dynItem.tween(time*0.25) do end
  dynAnim.setBackArmState "mid"
  dynAnim.setArmAngles(0, 0)
  for v in dynItem.tween(time*0.1) do end
  mcontroller.addMomentum {dynItem.dir * 25, 0}
  dynAnim.setBackArmState "out"
  dynAnim.setArmAngles(0, math.pi * 0.25/8)
  strike(time, dmgtype "fist", dynItem.offsetPoly(polyFan(math.pi * 2/8, 5), true, 0), dynItem.impulse({5*dynItem.dir, 3}, 0.64))
  for v in dynItem.tween(time*0.4) do end
  dynAnim.setBackArmState "mid"
  dynAnim.setArmAngles(0, 0)
  for v in dynItem.tween(time*0.1) do end
  setIdleStance()
  for v in dynItem.tween(time*0.4) do end
  --for v in dynItem.tween(time*0.6) do end
  
  --if dynItem.buffered(true) then return sweepKick end
  if dynItem.buffered() then
    if mcontroller.crouching() then return sweepKick end
    return punch1
  end
end

function sweepKick()
  local time = 0.4
  local mparams = {
    airJumpProfile = {
      jumpSpeed = 0,
    },
  }
  
  --[[for v in dynItem.tween(0.1) do
    mcontroller.controlCrouch()
  end--]]
  
  dynAnim.setArmStates("mid")
  dynAnim.setArmAngles(math.pi * -3/8)
  activeItem.setHoldingItem(true)
  
  dynItem.startBuffer()
  
  mcontroller.controlParameters(mparams)
  
  mcontroller.controlJump(true)
  mcontroller.setYVelocity(math.max(32, mcontroller.yVelocity()))
  strike(time, dmgtype "fist", dynItem.offsetPoly(polyFan(math.pi * 3.5/8, 7), true, math.pi * 2/8), dynItem.impulse({7*dynItem.dir, 15}, 0.85))
  for v in dynItem.tween(time*.7) do
    local vv = v^0.4
    mcontroller.setRotation(vv * math.pi * 2 * dynItem.dir)
  end
  mcontroller.setRotation(0)
  mcontroller.clearControls()
  activeItem.setHoldingItem(false)
  for v in dynItem.tween(time*.3) do end
  if dynItem.buffered() then return punch1 end
end
