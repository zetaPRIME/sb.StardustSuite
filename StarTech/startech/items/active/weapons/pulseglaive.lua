require "/lib/stardust/dynitem.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"

function asset(f) return string.format("/startech/items/active/weapons/%s", f) end

function init()
  activeItem.setHoldingItem(true)
  activeItem.setTwoHandedGrip(false)
  activeItem.setBackArmFrame("rotation")
  
  animator.setPartTag("haft", "partImage", --[["/items/active/weapons/melee/spear/feneroxspear.png" or]] asset "pulseglaive.png")
  --animator.setPartTag("wave", "directives", "?multiply=ffffff00")
  
  activeItem.setDamageSources()
  
  --
end

function uninit()
  --
end

dynItem.install()
dynItem.setAutoAim(false)
dynItem.aimVOffset = -5/8

local cfg = {
  comboTime = 1/3,
  
  manaCost = 5,
  baseDamage = 5,
  
  animTime = 1/3,
  distance = 30,
  
  altManaCost = 12,
  altBaseDamage = 7,
}

local buffered = false

local ang = 0.0

-- buffer task
dynItem.addTask(function() while true do
  if dynItem.firePress then buffered = 1 elseif dynItem.altFirePress then buffered = 2 end
  
  --dynItem.aimAt(dynItem.aimDir, math.pi * -0.55)
  
  --[[animator.resetTransformationGroup("weapon")
  animator.rotateTransformationGroup("weapon", ang)
  dynItem.normalizeTransformationGroup("weapon")
  ang = ang + script.updateDt() * 0.25]]
  
  coroutine.yield()
end end)

local function enc(stat)
  return "::" .. sb.printJson(stat)
end

function idle()
  activeItem.setTwoHandedGrip(false)
  while true do
    dynItem.aimAt(dynItem.aimDir, math.pi * -0.575)
    animator.resetTransformationGroup("weapon")
    
    if dynItem.firePress then return swing end
    coroutine.yield()
  end
end

function swing()
  activeItem.setTwoHandedGrip(true)
  animator.playSound("swing")
  local len = 2.0
  local m = 0.0
  local mx = 2.1
  local md = 0.3
  for v in dynItem.tween(0.0, 1.0, cfg.comboTime*0.2) do
    v = v^0.25
    local a = util.lerp(v, mx, m)
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - a)
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, len * util.lerp(v, 0.0, 1.0)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + a)
  end
  for v, f in dynItem.tween(0.0, 1.5, cfg.comboTime*0.8) do
    v = math.min(v, 1.0)
    local a = util.lerp(v^3, m, md)
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - a)
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, len * util.lerp(v, 1.0, 1.0)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + a)
  end
  while dynItem.fire do
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    coroutine.yield()
  end
end

dynItem.comboSystem(idle)

-- fire task
if false then dynItem.addTask(function() while true do
  if buffered == 1 and status.consumeResource("aetheri:mana", cfg.manaCost) then -- primary fire
    -- set up for the actual toss
    activeItem.setHoldingItem(true)
    activeItem.setFrontArmFrame("run.3")
    activeItem.setBackArmFrame("jump.3")
    coroutine.yield() -- single frame delay because otherwise the hand position is incorrect (*W H Y*)
    dynItem.setAutoAim(false) -- lock aim during animation
    animator.playSound("fire")
    buffered = 0
    
    activeItem.setFrontArmFrame("rotation")
    activeItem.setBackArmFrame("rotation")
    
    local tpos = vec2.add(mcontroller.position(), vec2.mul(vec2.norm(vec2.sub(activeItem.ownerAimPosition(), mcontroller.position())), cfg.distance * 1.1))
    local dir = mcontroller.facingDirection()
    
    local dmg = cfg.baseDamage * status.stat("powerMultiplier", 1.0) * status.stat("aetheri:skillPowerMultiplier", 0.0)
    local dmgProps = {
      damage = dmg,
      team = activeItem.ownerTeam(),
      damageSourceKind = "shortsword", -- quietish slash sound
      statusEffects = { "aetheri:aethertouched", { effect = "stardustlib:armorstrip", duration = 0.005 },
        enc { tag = "spaceDamageBonus" },
        enc { tag = "impulse", vec = vec2.mul(vec2.norm(vec2.sub(activeItem.ownerAimPosition(), mcontroller.position())), 15) } },
      knockback = 0.1,
      rayCheck = false,
      blahblah = "This is a test.",
      damageRepeatGroup = "aetheri:wave=" .. sb.nrand(),
      damageRepeatTimeout = cfg.animTime * 0.4,
    }
    -- double damage on top of the multiplier to compensate for lack of double-hit potential; risk-reward trying to "tipper" it
    local critDmgProps = util.mergeTable(util.mergeTable({ }, dmgProps), { damage = dmg * 2 * status.stat("aetheri:skillCritMultiplier" )})
    
    local pDist = 0
    for t in dynItem.tween(0.0, 1.0, cfg.animTime) do
      dynItem.aimAtPos(tpos, dir)
      local distP = math.sin(t * math.pi)
      local dist = distP * cfg.distance
      local crit = distP >= 0.75 -- crit at end of flight
      
      local sc = 1
      local sc2 = 1
      if t < 0.5 then
        local tt = t*2
        sc = util.lerp(tt^0.25, 0.5, 1)
        sc2 = sc^2
      else
        local tt = t*2 - 1
        sc = -1 - tt
        sc2 = 1.0 - (tt*0.75)
      end
      
      activeItem.setDamageSources {
        util.mergeTable({ poly = dynItem.offsetPoly(capsuleSweep(pDist, dist, 2.5*sc2)) }, crit and critDmgProps or dmgProps),
      }
      pDist = dist
      
      animator.setPartTag("wave", "directives", directives)
      animator.resetTransformationGroup("wave")
      animator.scaleTransformationGroup("wave", {sc, sc2})
      animator.translateTransformationGroup("wave", {dist, 0})
      animator.setLightColor("muzzleFlash", color.lightColor(lightColor, 0.64))
    end
    
    activeItem.setDamageSources()
    activeItem.setHoldingItem(false)
    dynItem.setAutoAim(true)
    animator.setPartTag("wave", "directives", "?multiply=ffffff00")
    animator.setLightColor("muzzleFlash", color.lightColor(lightColor, 0))
    
    --
  elseif false and buffered == 2 and status.consumeResource("aetheri:mana", cfg.altManaCost) then -- alt fire
    --
  else buffered = false end
  
  coroutine.yield()
end end) end
