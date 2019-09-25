-- weapon extension
require "/lib/stardust/weaponutil.lua"

local follow = false
local armAngle = 0
local setArmAngle = activeItem.setArmAngle
function activeItem.setArmAngle(angle, f)
  follow = not not f
  if follow then angle = angle - mcontroller.rotation() * mcontroller.facingDirection() end
  armAngle = angle
  return setArmAngle(armAngle)
end
local handPosition = activeItem.handPosition
function activeItem.handPosition(off)
  if not follow then return handPosition(off) end
  setArmAngle(armAngle + mcontroller.rotation() * mcontroller.facingDirection())
  local vec = handPosition(off)
  setArmAngle(armAngle)
  return vec
end

local function rotatePoly(p, rot, off)
  --off = off or {0, 0}
  if not p then return nil end
  if rot == 0 and (not off or vec2.eq(off, {0, 0})) then return p end
  local np = { }
  for k, v in pairs(p) do
    if off then v = vec2.add(v, off) end
    np[k] = vec2.rotate(v, rot)
  end
  return np
end

local function imbue(src, imb)
  local res = util.mergeTable({ }, src or { }) -- copy
  util.appendLists(res, imb) -- and append
  if res[1] then return res end
  return nil
end

local setDamageSources = activeItem.setDamageSources
function activeItem.setDamageSources(lst)
  local nl
  if lst then
    local rot = mcontroller.rotation()
    --if rot == 0 then return setDamageSources(lst) end -- early out if not rotated
    local imbues = weaponUtil.getStatusImbue()
    nl = { }
    for _, s in pairs(lst) do
      local ms = util.mergeTable({ }, s)
      table.insert(nl, ms)
      ms.poly = rotatePoly(ms.poly, rot)
      ms.line = rotatePoly(ms.line, rot)
      ms.statusEffects = imbue(ms.statusEffects, imbues)
    end
  end
  return setDamageSources(nl)
end

local setItemDamageSources = activeItem.setItemDamageSources
function activeItem.setItemDamageSources(lst)
  local nl
  if lst then
    local rot = mcontroller.rotation() * mcontroller.facingDirection()
    --if rot == 0 then return setItemDamageSources(lst) end -- early out if not rotated
    local imbues = weaponUtil.getStatusImbue()
    --local off = handPosition()
    nl = { }
    for _, s in pairs(lst) do
      local ms = util.mergeTable({ }, s)
      table.insert(nl, ms)
      ms.poly = rotatePoly(ms.poly, rot, off)
      ms.line = rotatePoly(ms.line, rot, off)
      ms.statusEffects = imbue(ms.statusEffects, imbues)
    end
  end
  return setItemDamageSources(nl)
end

-- imbue projectiles
-- TODO: make sure this only applies to projectiles that *hit enemies*
-- TODO: maybe make this apply to explosions as well (actionOnReap stuff)
local spawnProjectile = world.spawnProjectile
function world.spawnProjectile(name, pos, src, dir, track, params)
  local imbues = weaponUtil.getStatusImbue()
  local cfg = root.projectileConfig(name)
  params.statusEffects = imbue(params and params.statusEffects or cfg.statusEffects, imbues)
  return spawnProjectile(name, pos, src, dir, track, params)
end
