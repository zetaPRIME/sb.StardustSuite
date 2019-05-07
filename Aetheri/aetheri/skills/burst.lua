require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/lib/stardust/playerext.lua"

--[[ TODO:
  move some of this into a clean library
  damage bonus from velocity
]]

local damage

function init()
  activeItem.setHoldingItem(true)
  activeItem.setTwoHandedGrip(false)
  activeItem.setBackArmFrame("rotation")
  
  damage = config.getParameter("baseDamage", 1)
  
  animator.setPartTag("burst", "partImage", "/aetheri/skills/burst.png")
  animator.setPartTag("burst", "directives", "?multiply=ffffff00")
end

function uninit()
  --
end

local cooldown = 0
local anim = 0

local cooldownTime = 0.35
local animTime = 1/6

local armAngle = 0
local handPos = {1, 0}
local function offsetPoly(p)
  local r = { }
  local rot, scale = armAngle, {mcontroller.facingDirection(), 1}
  for _, pt in pairs(p) do
    table.insert(r, vec2.add(vec2.mul( vec2.rotate(vec2.add(pt, handPos), rot), scale), {0, mcontroller.crouching() and -1 or 0}))
  end
  return r
end

local lastFireMode
local buffered
function update(dt, fireMode, shiftHeld)
  if fireMode == lastFireMode then fireMode = nil else lastFireMode = fireMode end
  local aimPos = vec2.add(activeItem.ownerAimPosition(), vec2.mul(mcontroller.velocity(), dt))
  local angle, dir = activeItem.aimAngleAndDirection(0, aimPos)
  if anim == 0 then
    activeItem.setFacingDirection(dir)
  end
  
  cooldown = math.max(cooldown - dt / cooldownTime, 0)
  anim = math.max(anim - dt / animTime, 0)
  
  if cooldown <= 0.75 and fireMode == "primary" then buffered = true end
  if cooldown == 0 and buffered then
    buffered = false
    cooldown = 1
    anim = 1
    activeItem.setFacingDirection(dir)
    activeItem.setArmAngle(angle - mcontroller.rotation() * dir) armAngle = angle
    animator.playSound("fire")
    local dmg = damage * status.stat("powerMultiplier", 1.0)
    activeItem.setDamageSources({{
      poly = offsetPoly{ {0, -1.5}, {-1.5, 0}, {0, 1.5}, {10, 0} },
      damage = dmg,
      --trackSourceEntity = damageConfig.trackSourceEntity,
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      damageSourceKind = "plasma",
      --damageSourceKind = damageConfig.damageSourceKind,
      --statusEffects = damageConfig.statusEffects,
      knockback = 22,
      rayCheck = true,
      damageRepeatTimeout = 0,
    }})
  else
    activeItem.setDamageSources() -- null
  end
  
  local visMult = anim^3
  animator.setPartTag("burst", "directives", string.format("?multiply=ffffff%02x", math.floor(0.5 + visMult * 255)))
  animator.resetTransformationGroup("weapon")
  animator.scaleTransformationGroup("weapon", {1 + (1-anim) * -0.1, anim^2})
  animator.setLightColor("muzzleFlash", { 216 * anim, 210 * anim, 255 * anim })
  activeItem.setHoldingItem(anim > 0)
  activeItem.setFrontArmFrame((anim < 0.32) and "run.3" or "rotation")
  activeItem.setBackArmFrame((anim < 0.32) and "jump.3" or "rotation")
  
end
