require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"

--[[ TODO:
  move some of this into a clean library
  damage bonus from velocity
]]

local burstReplace = {"fefffe", "d8d2ff", "b79bff", "8e71da"}
local directives = ""
local lightColor = burstReplace[2]

function updateColors()
  -- recolor to match user's core palette
  local appearance = status.statusProperty("aetheri:appearance", { })
  if appearance.palette then
    directives = color.replaceDirective(burstReplace, appearance.palette)
    lightColor = appearance.glowColor or appearance.palette[2]
  end
end

local damage

function init()
  activeItem.setHoldingItem(true)
  activeItem.setTwoHandedGrip(false)
  activeItem.setBackArmFrame("rotation")
  
  damage = config.getParameter("baseDamage", 1)
  
  animator.setPartTag("burst", "partImage", "/aetheri/skills/burst.png")
  animator.setPartTag("burst", "directives", "?multiply=ffffff00")
  
  animator.setSoundPitch("fireHum", 1.0, 0)
  animator.setSoundVolume("fireHum", 0.75, 0)
  animator.setSoundPosition("fireHum", { 9, 0 }) -- near the tip of the burst
  
  updateColors()
  message.setHandler("aetheri:paletteChanged", updateColors)
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
  
  local cost = 5
  
  if cooldown <= 0.75 and fireMode == "primary" and status.resource("aetheri:mana") >= cost then buffered = true end
  if cooldown == 0 and buffered and status.consumeResource("aetheri:mana", cost) then
    buffered = false
    cooldown = 1
    anim = 1
    activeItem.setFacingDirection(dir)
    activeItem.setArmAngle(angle - mcontroller.rotation() * dir) armAngle = angle
    animator.playSound("fire")
    animator.playSound("fireHum")
    local velMult = 1 + util.clamp(vec2.dot(vec2.norm(vec2.sub(aimPos, mcontroller.position())), vec2.norm(mcontroller.velocity())), 0, 1) * util.clamp(vec2.mag(mcontroller.velocity()) / 100, 0, 1) * 1
    local dmg = damage * velMult * status.stat("powerMultiplier", 1.0) * status.stat("aetheri:skillPowerMultiplier", 0.0)
    activeItem.setDamageSources({{
      poly = offsetPoly{ {0, -1.5}, {-1.5, 0}, {0, 1.5}, {10, 0} },
      damage = dmg,
      --trackSourceEntity = damageConfig.trackSourceEntity,
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      damageSourceKind = "plasma",
      statusEffects = { "aetheri:aethertouched" },
      knockback = 22,
      rayCheck = true,
      damageRepeatTimeout = 0,
    }})
  else
    activeItem.setDamageSources() -- null
  end
  
  local visMult = anim^3
  animator.setPartTag("burst", "directives", string.format("%s?multiply=ffffff%02x", directives, math.floor(0.5 + visMult * 255)))
  animator.resetTransformationGroup("weapon")
  animator.scaleTransformationGroup("weapon", {1 + (1-anim) * -0.1, anim^2})
  animator.setLightColor("muzzleFlash", color.lightColor(lightColor, anim))
  activeItem.setHoldingItem(anim > 0)
  activeItem.setFrontArmFrame((anim < 0.32) and "run.3" or "rotation")
  activeItem.setBackArmFrame((anim < 0.32) and "jump.3" or "rotation")
  
end
