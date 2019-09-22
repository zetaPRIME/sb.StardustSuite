require "/lib/stardust/dynitem.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"

function asset(f) return string.format("/startech/items/active/weapons/%s", f) end

function init()
  activeItem.setHoldingItem(true)
  activeItem.setTwoHandedGrip(false)
  activeItem.setBackArmFrame("rotation")
  
  animator.setSoundVolume("open", 1.5)
  
  animator.setGlobalTag("wave", "energyDirectives", "?multiply=ffffff00")
  
  animator.setPartTag("haft", "partImage", asset "pulseglaive-haft.png")
  animator.setPartTag("lens", "partImage", asset "pulseglaive-lens.png")
  animator.setPartTag("blade1", "partImage", asset "pulseglaive-blade1.png")
  animator.setPartTag("blade1e", "partImage", asset "pulseglaive-blade1e.png")
  animator.setPartTag("blade2", "partImage", asset "pulseglaive-blade2.png")
  animator.setPartTag("blade2e", "partImage", asset "pulseglaive-blade2e.png")
  
  activeItem.setDamageSources()
  
  --
end

function uninit()
  --
end

dynItem.install()
dynItem.setAutoAim(false)
dynItem.aimVOffset = -4/8

local cfg = {
  thrustTime = 1/3,
  slashTime = 2/5,
  
  pulseTime = 1/4,
  openTime = 1/5,
  
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

function animBlade(v)
  animator.resetTransformationGroup("arm1a")
  animator.resetTransformationGroup("arm1b")
  animator.resetTransformationGroup("arm2a")
  animator.resetTransformationGroup("arm2b")
  
  local o1 = util.lerp(v, 0.0, math.pi*0.85)
  local o2 = o1-util.lerp(v, 0.0, math.pi*0.25)
  
  -- a is the blade, b is the armature
  
  animator.rotateTransformationGroup("arm1a", o2)
  animator.rotateTransformationGroup("arm1b", -o1)
  animator.rotateTransformationGroup("arm2a", -o2)
  animator.rotateTransformationGroup("arm2b", o1)
  
  --[[animator.translateTransformationGroup("arm1a", {0, 3/8})
  animator.translateTransformationGroup("arm2a", {0, 2/8})
  animator.translateTransformationGroup("arm1b", {1/8, 8/8 - v*2/8})
  animator.translateTransformationGroup("arm2b", {-2/8, 7/8})
  -- a2 7/8 2/8 ]]
  
  animator.translateTransformationGroup("arm1b", {(1 - v*1.0)/8, (11 - v*7)/8})
  animator.translateTransformationGroup("arm2b", {-(2 + v*0.0)/8, (9 - v*4.25)/8})
end

do
  local pulseId = -1
  function cancelPulse() pulseId = (pulseId + 1) % 16384 return pulseId end
  function setEnergy(amt)
    cancelPulse()
    animator.setGlobalTag("energyDirectives", string.format("?multiply=ffffff%02x", math.floor(0.5 + util.clamp(amt, 0.0, 1.0) * 255)))
  end
  function pulseEnergy(amt)
    local id = cancelPulse()
    dynItem.addTask(function()
      for v in dynItem.tween(cfg.pulseTime * amt) do
        if pulseId ~= id then return nil end -- cancel if signaled
        v = math.min((1.0-v) * amt, 1.0) ^ 0.333
        animator.setGlobalTag("energyDirectives", string.format("?multiply=ffffff%02x", math.floor(0.5 + v * 255)))
      end
    end)
  end
end

function idle()
  activeItem.setTwoHandedGrip(false)
  animBlade(0)
  while true do
    animator.resetTransformationGroup("weapon")
    dynItem.aimAt(dynItem.aimDir, math.pi * -0.575)
    
    if dynItem.firePress then return swing end
    coroutine.yield()
  end
end dynItem.comboSystem(idle)

function swing()
  activeItem.setTwoHandedGrip(true)
  animator.playSound("swing")
  pulseEnergy(1.25)
  local len = 2.0
  local m = 0.0
  local mx = 1.7
  local md = 0.3
  for v in dynItem.tween(cfg.thrustTime*0.2) do
    local vv = v^0.125
    local a = util.lerp(vv, mx, m)
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - a)
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, len * util.lerp(v^0.5, 0.0, 1.0)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + a)
  end
  for v, f in dynItem.tween(cfg.thrustTime*0.8) do
    v = math.min(v*1.5, 1.0)
    local a = util.lerp(v^3, m, md)
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - a)
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, len * util.lerp(v, 1.0, 1.0)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + a)
  end
  if dynItem.fire then return test_open end
  while dynItem.fire do
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    coroutine.yield()
  end
end

function test_open()
  local md = 0.3
  animator.playSound("open")
  for v in dynItem.tween(cfg.openTime) do
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    animBlade(0.5 + math.cos(v * math.pi) * -0.5)
  end
  while dynItem.fire do
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    coroutine.yield()
  end
end

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
