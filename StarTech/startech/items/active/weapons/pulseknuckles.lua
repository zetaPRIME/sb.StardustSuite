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

local effTime = 0.175
local effCount = 0
local effLayer = {"Player+1", 0}
function swoosh(angle, dir)
  local id = "" .. effCount
  effCount = effCount + 1
  local e = { image = assetRaw "pulseglaive-slashfx" .. "%s?scalebilinear=1;0.75%s", fullbright = true, imageParams = { }, rotation = angle, mirrored = dir < 1, layer = effLayer }
  dynAnim.effects[id] = e
  dynItem.addTask(function()
    for v in dynItem.tween(effTime) do
      e.position = vec2.rotate({dir * (0 + v^0.75*5), 0}, angle*dir)
      e.scale = (1.0 + v^0.75*0.5)
      e.imageParams[1] = energyParams[1]
      e.imageParams[2] = color.alphaDirective(1-v)
    end
    dynAnim.effects[id] = nil -- kill when done
  end)
end

function jab(angle, dir)
  local id = "" .. effCount
  effCount = effCount + 1
  local e = { image = assetRaw "pulseknuckles-jabfx" .. "%s%s", fullbright = true, imageParams = { }, rotation = angle, mirrored = dir < 1, layer = effLayer }
  dynAnim.effects[id] = e
  local sp = dynItem.shoulderPos
  dynItem.addTask(function()
    for v in dynItem.tween(effTime) do
      e.position = vec2.add(vec2.rotate({dir * (1.25 + v^0.75*3), 0}, angle*dir), sp)
      e.scale = (1.0 + v^0.75*1)
      e.imageParams[1] = energyParams[1]
      e.imageParams[2] = color.alphaDirective(1-v)
    end
    dynAnim.effects[id] = nil -- kill when done
  end)
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
  local ground = mcontroller.onGround()
  setIdleStance()
  animator.playSound "jab"
  animator.playSound "beam"
  dynItem.startBuffer()
  
  --for v in dynItem.tween(time*0.25) do end
  dynAnim.setFrontArmState "mid"
  dynAnim.setArmAngles(0, math.pi * -4/8)
  for v in dynItem.tween(time*0.1) do end
  dynAnim.setFrontArmState "out"
  dynAnim.setArmAngles(math.pi * 0.25/8, math.pi * -2/8)
  strike(time, dmgtype "fist", dynItem.offsetPoly(polyFan(math.pi * 2/8, 5), true, 0), dynItem.impulse({5*dynItem.dir, 3}, 0.64))
  jab(0, dynItem.dir)
  for v in dynItem.tween(time*0.4) do
    if ground then mcontroller.setXVelocity(dynItem.dir * 10) end
  end
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
  local ground = mcontroller.onGround()
  setIdleStance()
  animator.playSound "jab"
  animator.playSound "beam"
  dynItem.startBuffer()
  
  --for v in dynItem.tween(time*0.25) do end
  dynAnim.setBackArmState "mid"
  dynAnim.setArmAngles(0, 0)
  for v in dynItem.tween(time*0.1) do end
  dynAnim.setBackArmState "out"
  dynAnim.setArmAngles(0, math.pi * 0.25/8)
  strike(time, dmgtype "fist", dynItem.offsetPoly(polyFan(math.pi * 2/8, 5), true, 0), dynItem.impulse({5*dynItem.dir, 3}, 0.64))
  jab(0, dynItem.dir)
  for v in dynItem.tween(time*0.4) do
    if ground then mcontroller.setXVelocity(dynItem.dir * 10) end
  end
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
  local ground = mcontroller.onGround()
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
  animator.playSound "kick"
  animator.playSound "beam"
  
  dynItem.startBuffer()
  
  mcontroller.controlParameters(mparams)
  
  mcontroller.controlJump(true)
  
  mcontroller.setYVelocity(math.max(ground and 37 or 10, mcontroller.yVelocity()))
  strike(time, dmgtype "fist", dynItem.offsetPoly(polyFan(math.pi * 3.5/8, 7), true, math.pi * 2/8), dynItem.impulse({7*dynItem.dir, ground and 15 or 35}, 0.85))
  swoosh(math.pi * 2/8, dynItem.dir)
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
