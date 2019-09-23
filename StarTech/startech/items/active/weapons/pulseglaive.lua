require "/lib/stardust/dynitem.lua"
require "/lib/stardust/weaponutil.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"

function asset(f) return string.format("/startech/items/active/weapons/pulseglaive-%s.png", f) end

local cfg
function init()
  activeItem.setHoldingItem(true)
  activeItem.setTwoHandedGrip(false)
  activeItem.setBackArmFrame("rotation")
  
  animator.setSoundVolume("open", 1.5)
  animator.setSoundVolume("beam", 0.75)
  
  animator.setGlobalTag("wave", "energyDirectives", "?multiply=ffffff00")
  
  animator.setPartTag("haft", "partImage", asset "haft")
  animator.setPartTag("lens", "partImage", asset "lens")
  animator.setPartTag("blade1", "partImage", asset "blade1")
  animator.setPartTag("blade1e", "partImage", asset "blade1e")
  animator.setPartTag("blade2", "partImage", asset "blade2")
  animator.setPartTag("blade2e", "partImage", asset "blade2e")
  
  activeItem.setDamageSources()
  cfg.baseDps = cfg.baseDps * root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))
  --
end

function uninit()
  --
end

dynItem.install()
dynItem.setAutoAim(false)
dynItem.aimVOffset = -4/8

--[[local]] cfg = {
  thrustTime = 1/3,
  slashTime = 1/4,
  
  openTime = 1/5,
  
  baseDps = 15,
  
  -- visuals
  idleHoldAngle = math.pi * -0.575,
  thrustLenth = 2.0,
  pulseTime = 1/4,
  fxTime = 1/8,
}

local function enc(stat)
  return "::" .. sb.printJson(stat)
end

function strike(dmg, type, poly)
  local np = #poly
  activeItem.setDamageSources { {
    poly = np > 2 and poly,
    line = np == 2 and poly,
    damage = dmg * cfg.baseDps * status.stat("powerMultiplier", 1.0),
    team = activeItem.ownerTeam(),
    damageSourceKind = type,
    statusEffects = weaponUtil.imbue {
      enc { tag = "spaceDamageBonus" },
    },
    knockback = {mcontroller.facingDirection(), 20},
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
        animator.setPartTag("fx", "fxDirectives", string.format("?multiply=ffffff%02x", math.floor(0.5 + a * 255)))
        
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
  animBlade(0)
  while true do
    animator.resetTransformationGroup("weapon")
    dynItem.aimAt(dynItem.aimDir, cfg.idleHoldAngle)
    
    if dynItem.firePress then dynItem.firePress = false return thrust end
    coroutine.yield()
  end
end dynItem.comboSystem(idle)

function fail() -- not enough fp
  animator.playSound("fail")
end

function thrust(num)
  num = num or 1
  local buffered, released
  local function inp()
    if dynItem.firePress then buffered = true end
    if not dynItem.fire then released = true end
  end
  
  activeItem.setTwoHandedGrip(true)
  animator.playSound("thrust")
  animator.playSound("beam")
  pulseEnergy(1.0)
  
  local len = cfg.thrustLenth
  local m = 0.05
  local mx = 1.7
  local md = 0.3
  for v in dynItem.tween(cfg.thrustTime*0.2) do inp()
    local vv = v^0.125
    local a = util.lerp(vv, mx, m)
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - a)
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, len * util.lerp(v^0.5, 0.0, 1.3)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + a)
  end
  
  -- damage
  strike(cfg.thrustTime, "spear", dynItem.offsetPoly({
    {5.5, -1},
    {-1.25, -0.5},
    {-1.25, 0.5},
    {5.5, 1},
    {10, 0},
  }, false, dynItem.aimAngle))
  -- fx
  throwFx("thrustfx", dynItem.aimDir, dynItem.aimAngle, {6, -2/8})
  
  for v, f in dynItem.tween(cfg.thrustTime*0.8) do inp()
    local rv = v
    v = util.clamp(v*1.5 - 0.5, 0.0, 1.0)
    local a = util.lerp(v^3, m, md)
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - a)
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, len * util.lerp(v^0.25, 1.3, 1)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + a)
  end
  if not released then return beamOpen end
  if buffered then return slash end
  while dynItem.fire do
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    coroutine.yield()
  end
end

local function sigexp(n, x)
  local s = n >= 0 and 1 or -1
  return math.abs(n)^x * s
end

function slash(num)
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
  local len = cfg.thrustLenth
  
  activeItem.setTwoHandedGrip(true)
  animator.playSound("slash")
  animator.playSound("beam")
  pulseEnergy(1.0)
  
  animator.resetTransformationGroup("weapon")
  animator.translateTransformationGroup("weapon", {0, cfg.thrustLenth})
  animator.rotateTransformationGroup("weapon", math.pi * -0.5)
  
  -- actual swing (and accompanying fx)
  strike(cfg.slashTime, "shortsword", dynItem.offsetPoly(polyFan(sweepWidth, 11), true, dynItem.aimAngle))
  throwFx("slashfx", dynItem.aimDir, dynItem.aimAngle, {6.5, 0}, 0.9) -- 0.8 == 1/1.25
  
  for v in dynItem.tween(cfg.slashTime * 0.2) do inp() -- main swing
    --v = math.sin(v * math.pi)
    local sv = 0.5 + math.cos(v * math.pi) * -0.5
    dynItem.aimAt(dir, aim - util.lerp(sv, -1.0, 1.0) * sweepWidth * slashDir)
    
    --[[animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, len})
    animator.rotateTransformationGroup("weapon", math.pi * (-0.5 + (1.0-v) * slashDir * 0.15 ))]]
  end
  
  for v in dynItem.tween(cfg.slashTime * 0.8) do inp() -- overswing
    dynItem.aimAt(dir, aim - (sweepWidth + math.sin(((v^0.75)*0.75)*math.pi) * 0.075 * math.pi) * slashDir)
  end
  
  if buffered then
    if num > 1 then return thrust, true end
    return slash, num + 1
  end
end

function beamOpen()
  local md = 0.3
  animator.playSound("open")
  for v in dynItem.tween(cfg.openTime) do
    local sv = 0.5 + math.cos(v * math.pi) * -0.5
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    animBlade(sv)
    local md = 0.3
    animator.resetTransformationGroup("weapon")
    animator.translateTransformationGroup("weapon", {0, cfg.thrustLenth * util.lerp(sv, 1.0, 0.4)})
    animator.rotateTransformationGroup("weapon", (math.pi * -0.5) + md)
  end
  while dynItem.fire do
    dynItem.aimAt(dynItem.aimDir, dynItem.aimAngle - md)
    coroutine.yield()
  end
end
