require "/startech/items/active/weapons/pulseweapon.lua"

assetPrefix "pulserifle-"

function init() initPulseWeapon()
  activeItem.setHoldingItem(true)
  activeItem.setTwoHandedGrip(true)
  
  --animator.setSoundVolume("finisher", 0.75)
  
  animator.setPartTag("body", "partImage", asset "body")
  animator.setPartTag("energy", "partImage", asset "energy")
  animator.setPartTag("muzzleflash", "partImage", asset "muzzleflash")
  
  -- hide any lingering fx
  animator.scaleTransformationGroup("fx", {0, 0})
  animator.scaleTransformationGroup("fx2", {0, 0})
  animator.scaleTransformationGroup("fx3", {0, 0})
  
  --
end

dynItem.install()
dynItem.setAutoAim(true)
dynItem.aimVOffset = 0/8 -- -4.5/8

cfg {
  assaultFireTime = 1/8,
  
  assaultPowerCost = 250,
  shotgunPowerCost = 1000,
}

function doBody()
  animator.resetTransformationGroup("body")
  animator.translateTransformationGroup("body", {12/8, 1/8})
end

function applyPunchthrough(line, pt)
  if not pt or pt <= 0 then return end
  
  local d = vec2.sub(line[2], line[1])
  line[2] = vec2.add(line[1], vec2.mul(vec2.norm(d), vec2.mag(d) + pt))
  return line
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
      dynItem.impulse(kb, 0),
    },
    --knockback = {0, 0},
    rayCheck = true,
    damageRepeatTimeout = 0,
  } }
end

function idle()
  --activeItem.setTwoHandedGrip(false)
  --activeItem.setOutsideOfHand(false)
  --activeItem.setCursor()
  --animBlade(0)
  
  doBody()
  animator.resetTransformationGroup("weapon")
  while true do
    --animator.resetTransformationGroup("weapon")
    --animator.rotateTransformationGroup("weapon", 0.1)
    --dynItem.aimAt(dynItem.aimDir, cfg.idleHoldAngle)
    
    if dynItem.firePress then dynItem.firePress = false return assaultFire end
    if dynItem.altFirePress then dynItem.altFirePress = false return thrust, true end -- for now just skip to the finisher
    coroutine.yield()
  end
end dynItem.comboSystem(idle)

function fail() -- not enough fp
  pulseEnergy(0.5) -- "attempt" to power up
  animator.stopAllSounds("fail")
  animator.playSound("fail")
end

local beamPt = {4, 0/8}

function assaultFire()
  if not drawPower(cfg.assaultPowerCost) then return fail end
  doBody()
  animator.playSound("fire")
  
  local dir, angle = dynItem.aimDir, dynItem.aimAngle
  
  local line = dynItem.offsetPoly({ {0, 2/8}, {150, 2/8} }, false, angle)
  local pos = vec2.add(mcontroller.position(), {0, 0})
  local lc = {vec2.add(pos, line[1]), vec2.add(pos, line[2])}
  lc[2] = world.lineCollision(lc[1], lc[2]) or lc[2]
  local lq = world.entityLineQuery(lc[1], lc[2], { includedTypes = {"creature"}, order = "nearest" })
  
  local hit
  for _, id in pairs(lq) do
    if world.entityCanDamage(entity.id(), id) then hit = id break end
  end
  if hit then -- intersect
    local hpos = world.entityPosition(hit)
    local ab = vec2.sub(line[2], line[1])
    local ap = vec2.sub(hpos, lc[1])
    local dist = vec2.dot(ab, ap) / (vec2.mag(ab))
    line[2] = vec2.add(line[1], vec2.mul(vec2.norm(ab), dist))
    applyPunchthrough(line, 5)
  else -- stop at tile collision
    line[2] = vec2.sub(lc[2], pos)
  end
  
  strike(cfg.assaultFireTime, dmgtype "plasmashotgun", line, 7)
  local dist = vec2.mag(vec2.sub(line[2], line[1])) - beamPt[1]
  
  animator.setPartTag("fx", "fxDirectives", "")
  animator.setPartTag("fx", "partImage", assetRaw "pulseglaive-beam")
  
  for v in dynItem.tween(cfg.assaultFireTime) do
    setEnergy(1 - v)
    animator.resetTransformationGroup("weapon")
    animator.rotateTransformationGroup("weapon", 0.05 * (1-v))
    animator.translateTransformationGroup("weapon", {-1.5/8 * (1-v), 0/8})
    
    animator.setPartTag("fx", "fxDirectives", color.alphaDirective((1-v) * 0.5))
    setFx("fx", dir, angle, beamPt, {dist*8 + 12, 0.125 * (1-v)})
  end
  if dynItem.fire then return assaultFire end
end
