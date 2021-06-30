require "/startech/items/active/weapons/pulseweapon.lua"

assetPrefix "pulserifle-"

function init() initPulseWeapon()
  activeItem.setHoldingItem(true)
  activeItem.setTwoHandedGrip(true)
  
  animator.setSoundVolume("fire", 0.85)
  
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
  assaultKnockback = 2.5, -- bit of stopping power but not enough to juggle
  assaultRange = 80, -- maximum tile range for assault rifle fire
  -- shorter than the pulsestrike glaive's 150
  assaultSpread = 0.015, -- maximum angle variance
  assaultPunchthrough = 5, -- base punchthrough
  
  shotgunFireTime = 2/3,
  shotgunDamageMult = 1.1, -- compensate for manual retrigger
  shotgunKnockback = 32, -- gtfo
  
  pulseTime = 1/4,
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

function shotVec(mag)
  local v = dynItem.aimVector(nil, nil, 1)
  if mcontroller.onGround() then v[2] = math.abs(v[2]) + 0.05 end -- reflect upwards if on ground
  return vec2.mul(vec2.norm(v), mag)
end

function setMuzzle(b)
  if b then animator.setGlobalTag("muzzleflashDirectives", "")
  else animator.setGlobalTag("muzzleflashDirectives", "?multiply=0000") end
end

function idle()
  -- kill fx
  animator.scaleTransformationGroup("fx", {0, 0})
  
  setMuzzle(false)
  activeItem.setCursor "/cursors/reticle0.cursor"
  
  doBody()
  animator.resetTransformationGroup("weapon")
  while true do
    
    if dynItem.firePress then dynItem.firePress = false return assaultFire end
    if dynItem.altFirePress then dynItem.altFirePress = false return shotgunFire end
    coroutine.yield()
  end
end dynItem.comboSystem(idle)

local beamPt = {4, 0/8}

function assaultFire()
  if not drawPowerFor(cfg.assaultFireTime) then return fail end
  doBody()
  animator.playSound("fire")
  
  local dir, angle = dynItem.aimDir, dynItem.aimAngle
  angle = spread(angle, cfg.assaultSpread / stats.accuracy, 3 * stats.accuracy)
  
  local line = dynItem.offsetPoly({ {0, 2/8}, {cfg.assaultRange, 2/8} }, false, angle)
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
    applyPunchthrough(line, cfg.assaultPunchthrough * stats.punchthrough)
  else -- stop at tile collision
    line[2] = vec2.sub(lc[2], pos)
  end
  
  strike(cfg.assaultFireTime, dmgtype "plasmashotgun", line, shotVec(cfg.assaultKnockback))
  local dist = vec2.mag(vec2.sub(line[2], line[1])) - beamPt[1]
  
  animator.setPartTag("fx", "fxDirectives", "")
  animator.setPartTag("fx", "partImage", assetRaw "pulseglaive-beam")
  
  setMuzzle(true)
  for v in dynItem.tween(cfg.assaultFireTime / stats.speed) do
    setEnergy(1 - v)
    activeItem.setCursor(string.format("/cursors/reticle%i.cursor", math.floor(0.5 + (1-v) * 2)))
    animator.resetTransformationGroup("weapon")
    animator.rotateTransformationGroup("weapon", 0.05 * (1-v))
    animator.translateTransformationGroup("weapon", {-1.5/8 * (1-v), 0/8})
    
    local bv = util.lerp(1-v, 0.5, 1)
    animator.setPartTag("fx", "fxDirectives", color.alphaDirective(bv * 0.75))
    setFx("fx", dir, angle, beamPt, {dist*8 + 12, 0.15 * util.lerp(1-v, 0.4, 1)})
  end
  setMuzzle(false)
  if dynItem.fire then return assaultFire end
end

local burstPt = {28/8, 1/8}
function shotgunFire()
  if not drawPowerFor(cfg.shotgunFireTime) then return fail end
  
  animator.playSound("shotgunFire")
  strike(cfg.shotgunFireTime * cfg.shotgunDamageMult, dmgtype "plasmashotgun",
    dynItem.offsetPoly(polyFan(math.pi * 0.05, 16), true, dynItem.aimAngle),
    shotVec(cfg.shotgunKnockback)
  )
  
  local buffered, released
  local function inp()
    if dynItem.altFirePress then buffered = true end
    if not dynItem.altFire then released = true end
  end
  
  animator.setPartTag("fx", "fxDirectives", "")
  animator.setPartTag("fx", "partImage", asset "shotgunfx")
  
  local dir, angle = dynItem.aimDir, dynItem.aimAngle
  for v in dynItem.tween(cfg.shotgunFireTime / stats.speed) do inp()
    local vv = (1-v)^3
    setEnergy(vv)
    
    activeItem.setCursor(string.format("/cursors/reticle%i.cursor", math.floor(0.5 + (vv) * 5)))
    
    animator.resetTransformationGroup("weapon")
    animator.rotateTransformationGroup("weapon", 0.15 * vv)
    animator.translateTransformationGroup("weapon", {-3/8 * vv, 0/8})
    
    animator.setPartTag("fx", "fxDirectives", color.alphaDirective(vv))
    local bv = math.max(0, 1-v*2)
    setFx("fx", dir, angle, burstPt, {bv^2 * 1.5, math.max(0, -1 + bv*2)})
  end
  --if buffered then return shotgunFire end
end
