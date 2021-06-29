require "/startech/items/active/weapons/pulseweapon.lua"

assetPrefix "pulseglaive-"

function init() initPulseWeapon()
  activeItem.setHoldingItem(true)
  activeItem.setTwoHandedGrip(false)
  activeItem.setBackArmFrame("rotation")
  
  animator.setSoundVolume("quickCharge", 0.75)
  animator.setSoundVolume("open", 1.5)
  animator.setSoundVolume("beam", 0.75)
  animator.setSoundPitch("beam", 1.0)
  animator.setSoundVolume("finisher", 0.75)
  
  animator.setPartTag("haft", "partImage", asset "haft")
  animator.setPartTag("lens", "partImage", asset "lens")
  animator.setPartTag("blade1", "partImage", asset "blade1")
  animator.setPartTag("blade1e", "partImage", asset "blade1e")
  animator.setPartTag("blade2", "partImage", asset "blade2")
  animator.setPartTag("blade2e", "partImage", asset "blade2e")
  
  -- hide any lingering fx
  animator.scaleTransformationGroup("fx", {0, 0})
  animator.scaleTransformationGroup("fx2", {0, 0})
  animator.scaleTransformationGroup("fx3", {0, 0})
  
  --
end

function uninit()
  --
end

dynItem.install()
dynItem.setAutoAim(false)
dynItem.aimVOffset = -4.5/8

cfg {
  thrustTime = 1/3,
  slashTime = 1/4,
  
  openTime = 1/5,
  
  chargeTime = 4/5,
  fireTime = 2/5,
  
  quickChargeMult = 0.5,
  
  --baseDps = 15,
  beamDamageMult = 1.05,
  
  meleePowerCost = 250,
  beamPowerCost = 1000,
  
  -- visuals
  idleHoldAngle = math.pi * -0.575,
  thrustLength = 2.0,
  pulseTime = 1/4,
  fxTime = 1/8,
}

function strike(dmg, type, poly, kb)
  kb = kb or 1.0
  local np = #poly
  activeItem.setDamageSources { {
    poly = (np > 2) and poly or nil,
    line = (np == 2) and poly or nil,
    damage = damage(dmg),
    team = activeItem.ownerTeam(),
    damageSourceKind = type,
    statusEffects = weaponUtil.imbue {
      baseStatus(),
      dynItem.impulse(25, 0.64),
    },
    --knockback = {0, 0},
    rayCheck = true,
    damageRepeatTimeout = 0,
  } }
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

function setFx(id, dir, angle, pos, scale, rot)
  scale = scale or 1
  rot = rot or 0
  
  animator.resetTransformationGroup(id)
  animator.scaleTransformationGroup(id, scale)
  animator.rotateTransformationGroup(id, rot)
  animator.translateTransformationGroup(id, pos)
  animator.rotateTransformationGroup(id, angle)
  
  if (dir < 0) then animator.scaleTransformationGroup(id, {-1, 1}) end
  dynItem.normalizeTransformationGroup(id)
end

do
  local fxId = -1
  function throwFx(type, dir, angle, offset, baseScale)
    fxId = (fxId + 1) % 16384
    local id = fxId
    offset = offset or {0, 0}
    baseScale = baseScale or 1
    dynItem.addTask(function()
      animator.setPartTag("fx", "partImage", asset(type))
      for v in dynItem.tween(cfg.fxTime) do
        if fxId ~= id then return nil end -- cancelable
        local a = (1.0-v)^0.5
        animator.setPartTag("fx", "fxDirectives", color.alphaDirective(a))
        
        animator.resetTransformationGroup("fx")
        animator.scaleTransformationGroup("fx", util.lerp(v, 1.0, 1.25) * baseScale)
        animator.translateTransformationGroup("fx", vec2.add(offset, {(v^0.5) * 3, 0}))
        animator.rotateTransformationGroup("fx", angle)
        
        if (dir < 0) then animator.scaleTransformationGroup("fx", {-1, 1}) end
        dynItem.normalizeTransformationGroup("fx")
      end
    end)
  end
end

function idle()
  activeItem.setTwoHandedGrip(false)
  activeItem.setOutsideOfHand(false)
  activeItem.setCursor()
  animBlade(0)
  
  while true do
    animator.resetTransformationGroup("weapon")
    dynItem.aimAt(dynItem.aimDir, cfg.idleHoldAngle)
    
    if dynItem.firePress then dynItem.firePress = false return thrust end
    if dynItem.altFirePress then dynItem.altFirePress = false return thrust, true end -- for now just skip to the finisher
    coroutine.yield()
  end
end dynItem.comboSystem(idle)

function cooldown() -- ...with a flourish
  activeItem.setTwoHandedGrip(false)
  activeItem.setOutsideOfHand(true)
  local start = dynItem.armAngle
  local apex = math.pi * 0.5
  
  local flipTime = 3/7 / stats.speed
  
  for v in dynItem.tween(flipTime * 0.3) do
    dynItem.aimAt(dynItem.aimDir, util.lerp(v^0.5, start, apex))
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, cfg.thrustLength * util.lerp(v, 1.0, 0.5)})
    animator.rotateTransformationGroup("weapon", util.lerp(v, (math.pi * -0.5) + 0.3, math.pi * -1.5))
  end
  for v in dynItem.tween(flipTime * 0.7) do
    if v >= 0.75 then activeItem.setOutsideOfHand(false) end
    dynItem.aimAt(dynItem.aimDir, util.lerp(v^2, apex, cfg.idleHoldAngle))
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, cfg.thrustLength * util.lerp(v, 0.5, 0.0)})
    animator.rotateTransformationGroup("weapon", util.lerp(v, math.pi * -1.5, math.pi * -2))
  end
  if dynItem.fire then return thrust end -- allow holding button to thrust again
end

function thrust(finisher)
  if not drawPower(cfg.meleePowerCost) then return fail end
  
  local buffered, released
  local function inp()
    if dynItem.firePress then buffered = true end
    if not dynItem.fire then released = true end
  end
  
  activeItem.setTwoHandedGrip(true)
  animator.playSound("thrust")
  animator.playSound("beam")
  if finisher then animator.playSound("finisher") end
  pulseEnergy(1.0)
  
  local len = cfg.thrustLength
  local m = 0.05
  local mx = 1.7
  local md = 0.3
  for v in dynItem.tween(cfg.thrustTime*0.2 / stats.speed) do inp()
    local vv = v^0.125
    local a = util.lerp(vv, mx, m)
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - a)
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, len * util.lerp(v^0.5, 0.0, 1.3)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + a)
  end
  
  -- damage
  strike(cfg.thrustTime * (finisher and 1.5 or 1.0), dmgtype "spear", dynItem.offsetPoly({
    {5.5, -1.5},
    {-1, -1},
    {-2, 0},
    {-1, 1},
    {5.5, 1.5},
    {10, 0},
  }, false, dynItem.aimAngle), finisher and 1.5)
  -- fx
  throwFx("thrustfx", dynItem.aimDir, dynItem.aimAngle, {6, -2/8}, finisher and 1.25 or 1.0)
  
  for v, f in dynItem.tween(cfg.thrustTime*0.8 / stats.speed) do inp()
    local rv = v
    v = util.clamp(v*1.5 - 0.5, 0.0, 1.0)
    local a = util.lerp(v^3, m, md)
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - a)
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, len * util.lerp(v^0.25, 1.3, 1)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + a)
  end
  if not released then return beamOpen, finisher end
  if finisher then return cooldown end
  if buffered then return slash end
  --
end

local function sigexp(n, x)
  local s = n >= 0 and 1 or -1
  return math.abs(n)^x * s
end

function slash(num)
  if not drawPower(cfg.meleePowerCost) then return fail end
  
  num = num or 1
  local slashDir = ((num % 2) == 0) and 1 or -1
  local buffered, released
  local function inp()
    if dynItem.firePress then buffered = true end
    if not dynItem.fire then released = true end
  end

  -- snapshot
  local dir, aim = dynItem.aimDir, dynItem.aimAngle
  local sweepWidth = math.pi * 0.27
  local len = cfg.thrustLength
  
  activeItem.setTwoHandedGrip(true)
  animator.playSound("slash")
  animator.playSound("beam")
  pulseEnergy(1.0)
  
  animator.resetTransformationGroup("weapon")
  animator.translateTransformationGroup("weapon", {0, cfg.thrustLength})
  animator.rotateTransformationGroup("weapon", math.pi * -0.5)
  
  -- actual swing (and accompanying fx)
  strike(cfg.slashTime, dmgtype "shortsword", dynItem.offsetPoly(polyFan(sweepWidth, 11), true, dynItem.aimAngle))
  throwFx("slashfx", dynItem.aimDir, dynItem.aimAngle, {6.5, 0}, 0.9) -- 0.8 == 1/1.25
  
  for v in dynItem.tween(cfg.slashTime * 0.2 / stats.speed) do inp() -- main swing
    --v = math.sin(v * math.pi)
    local sv = 0.5 + math.cos(v * math.pi) * -0.5
    dynItem.aimAt(dir, aim - util.lerp(sv, -1.0, 1.0) * sweepWidth * slashDir)
    
    --[[animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, len})
    animator.rotateTransformationGroup("weapon", math.pi * (-0.5 + (1.0-v) * slashDir * 0.15 ))]]
  end
  
  for v in dynItem.tween(cfg.slashTime * 0.8 / stats.speed) do inp() -- overswing
    dynItem.aimAt(dir, aim - (sweepWidth + math.sin(((v^0.75)*0.75)*math.pi) * 0.075 * math.pi) * slashDir)
  end
  
  if not released then return beamOpen end
  if buffered then
    if num > 1 then return thrust, true end
    return slash, num + 1
  end
end

local function chargeCursor(v)
  local a = math.min(math.floor((1.0-v) * 6), 5)
  activeItem.setCursor(string.format("/cursors/reticle%i.cursor", a))
end

function beamOpen(quick)
  local md = 0.3
  animator.playSound("open")
  if quick then animator.playSound("quickCharge") end
  local ct = (cfg.openTime / stats.charge) * (quick and cfg.quickChargeMult or 1)
  for v in dynItem.tween(ct) do
    local sv = 0.5 + math.cos(v * math.pi) * -0.5
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    animBlade(sv)
    chargeCursor(1.0 - sv)
    local md = 0.3
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, cfg.thrustLength * util.lerp(sv, 1.0, 0.4)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + md)
  end
  return beamCharge, quick
  --[[while dynItem.fire do
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    coroutine.yield()
  end]]
end

local beamPt = {40/8, dynItem.aimVOffset}

local flashTb = { 1.0, 0.8, 0.6 }
local function flash()
  return flashTb[math.floor((dynItem.time*30) % 3) + 1]
end

function beamCharge(quick)
  animator.setPartTag("fx2", "partImage", asset "orb")
  
  local md = 0.3
  animator.setSoundVolume("charge", 0)
  animator.playSound("charge", -1)
  local cancel
  local ct = (cfg.chargeTime / stats.charge) * (quick and cfg.quickChargeMult or 1)
  for v in dynItem.tween(ct) do
    if not dynItem.fire then cancel = true break end
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    animator.setSoundPitch("charge", util.lerp(v ^ 2, 0.5, 2.0))
    animator.setSoundVolume("charge", util.lerp(v, 0.75, 1.0))
    setEnergy(v * 0.5)
    chargeCursor(v)
    
    animator.setPartTag("fx2", "fxDirectives", "")
    setFx("fx2", dynItem.aimDir, dynItem.aimAngle, beamPt, v * flash(), dynItem.time * math.pi * 7)
    --[[animator.resetTransformationGroup("fx2")
    animator.rotateTransformationGroup("fx2", dynItem.time * math.pi * 7)
    animator.scaleTransformationGroup("fx2", v)
    animator.translateTransformationGroup("fx2", dynItem.offsetPoly{{-0.5/8, 24/8}}[1])
    dynItem.normalizeTransformationGroup("fx2")]]
  end
  if not cancel then animator.playSound("charged") end
  while dynItem.fire do
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    setEnergy(0.5)
    activeItem.setCursor("/cursors/chargeidle.cursor")
    
    animator.setPartTag("fx2", "fxDirectives", "")
    setFx("fx2", dynItem.aimDir, dynItem.aimAngle, beamPt, flash(), dynItem.time * math.pi * 7)
    
    coroutine.yield()
  end
  animator.stopAllSounds("charge")
  setEnergy(0)
  animator.scaleTransformationGroup("fx2", 0)
  if not cancel then return beamFire end
end

function beamFire()
  if not drawPower(cfg.beamPowerCost) then return fail end
  
  local md = 0.3
  local dir, angle = dynItem.aimDir, dynItem.aimAngle
  
  --animator.setSoundVolume("fire", 1.25)
  animator.playSound("fire")
  
  --throwFx("thrustfx", dir, angle, {6, -2/8}, -2)
  local line = dynItem.offsetPoly({ {0, 1/8}, {150, 1/8} }, false, angle)
  strike(cfg.beamDamageMult / util.lerp(0.5, 1, stats.charge), dmgtype "plasmashotgun", line, 2.2)
  
  local pos = vec2.add(mcontroller.position(), {0, 0})
  line = {vec2.add(pos, line[1]), vec2.add(pos, line[2])}
  line[2] = world.lineCollision(line[1], line[2]) or line[2]
  local dist = vec2.mag(vec2.sub(line[1], line[2]))
  dist = math.max(0, dist - 3.5)
  
  animator.setPartTag("fx", "fxDirectives", "")
  animator.setPartTag("fx", "partImage", asset "beam")
  
  for v in dynItem.tween(cfg.fireTime) do
    local cv = math.sin((v ^ 0.5) * math.pi) ^ 0.5
    local rca = 0--util.lerp(cv, 0, 0.12)--0.3
    --local md = util.lerp(cv, 0.3, 0.7)
    dynItem.aimAt(dir, angle - md - rca)
    setEnergy(1.0 - v)
    chargeCursor(1.0 - v^0.25)
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, cfg.thrustLength * util.lerp(cv, 0.4, 0.1)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + md + rca*3)
    
    animBlade(util.lerp(cv, 1, 1.25)) -- slight overextend from the force of firing
    
    local ov = math.max(0, 1.0 - v*2)
    local bv = math.max(0, 1.0 - v*4)
    setFx("fx2", dir, angle, beamPt, 1.25 * ov^2, dynItem.time * math.pi * 7)
    setFx("fx", dir, angle, beamPt, {(dist + 0.5 * (1.0 - bv)^2)*8.0, bv^2})
    
  end
  if dynItem.fire then return beamCharge end
end
