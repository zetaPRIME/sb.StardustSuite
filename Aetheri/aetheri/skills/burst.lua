require "/lib/stardust/dynitem.lua"
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

function init()
  activeItem.setHoldingItem(false)
  activeItem.setTwoHandedGrip(false)
  activeItem.setBackArmFrame("rotation")
  
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

dynItem.install()
dynItem.setAutoAim(true)

local cfg = {
  manaCost = 5,
  baseDamage = 5,
  
  animTime = 1/6,
  cooldownTime = 0.35,
  
  altManaCost = 12,
  altBaseDamage = 7,
}

local buffered = false

-- buffer task
dynItem.addTask(function() while true do
  if dynItem.firePress then buffered = 1 elseif dynItem.altFirePress then buffered = 2 end
  
  coroutine.yield()
end end)

-- fire task
dynItem.addTask(function() while true do
  if buffered == 1 and status.consumeResource("aetheri:mana", cfg.manaCost) then -- primary fire
    -- set up for the actual burst
    activeItem.setHoldingItem(true)
    activeItem.setFrontArmFrame("run.3")
    activeItem.setBackArmFrame("jump.3")
    coroutine.yield() -- single frame delay because otherwise the hand position is incorrect (*W H Y*)
    dynItem.setAutoAim(false) -- lock aim during animation
    animator.playSound("fire")
    animator.playSound("fireHum")
    local aimVec = vec2.norm(vec2.sub(dynItem.aimPos, mcontroller.position()))
    local up = vec2.dot(aimVec, {0, 1}) >= 0.9
    local velMult = 1 + util.clamp(vec2.dot(aimVec, vec2.norm(mcontroller.velocity())), 0, 1) * util.clamp(vec2.mag(mcontroller.velocity()) / 100, 0, 1) * 1
    local dmg = cfg.baseDamage * velMult * status.stat("powerMultiplier", 1.0) * status.stat("aetheri:skillPowerMultiplier", 0.0)
    activeItem.setDamageSources({{
      poly = dynItem.offsetPoly{ {0, -1.5}, {-1.5, 0}, {0, 1.5}, {10, 0} },
      damage = dmg,
      trackSourceEntity = true,
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      damageSourceKind = "plasma",
      statusEffects = { "aetheri:aethertouched" },
      knockback = {up and 0 or dynItem.aimDir, up and 32 or 25},
      rayCheck = true,
      damageRepeatTimeout = 0,
    }})
    for anim, first in dynItem.tween(1.0, 0.0, cfg.animTime) do
      if not first then activeItem.setDamageSources() end
      
      local visMult = anim^3
      animator.setPartTag("burst", "directives", string.format("%s?multiply=ffffff%02x", directives, math.floor(0.5 + visMult * 255)))
      animator.resetTransformationGroup("weapon")
      animator.scaleTransformationGroup("weapon", {1 + (1-anim) * -0.1, anim^2})
      animator.setLightColor("muzzleFlash", color.lightColor(lightColor, anim))
      activeItem.setFrontArmFrame((anim < 0.32) and "run.3" or "rotation")
      activeItem.setBackArmFrame((anim < 0.32) and "jump.3" or "rotation")
    end
    --util.wait(cfg.animTime)
    
    -- cooldown
    activeItem.setHoldingItem(false)
    dynItem.setAutoAim(true)
    buffered = false
    util.wait((cfg.cooldownTime - cfg.animTime) - script.updateDt())
  elseif buffered == 2 and status.consumeResource("aetheri:mana", cfg.altManaCost) then -- alt fire, sweep straight up
    dynItem.setAutoAim(false) -- lock aim during animation
    dynItem.aimAt(nil, 0)
    activeItem.setHoldingItem(true)
    activeItem.setFrontArmFrame("run.3")
    activeItem.setBackArmFrame("jump.3")
    
    if not mcontroller.groundMovement() and not mcontroller.liquidMovement() and not mcontroller.zeroG() then
      mcontroller.addMomentum{0, 50};
    end
    
    coroutine.yield()
    
    animator.playSound("sweep")
    animator.playSound("fireHum")
    
    local drg = "aetheri:burst.sweepUp=" .. sb.nrand()
    
    local t = cfg.animTime
    --if dynItem.shift then t = t * 10 end -- debug
    local dmg = cfg.altBaseDamage * status.stat("powerMultiplier", 1.0) * status.stat("aetheri:skillPowerMultiplier", 0.0)
    for v in dynItem.tween(0, 1, t) do
      activeItem.setFrontArmFrame("rotation")
      activeItem.setBackArmFrame("rotation")
      dynItem.aimAt(nil, util.easeInOutSin(v, -0.75, 1.75) * math.pi * 0.5)
      activeItem.setDamageSources({{
        poly = dynItem.offsetPoly{ {0, -1.5}, {-1.5, 0}, {0, 1.5}, {10, 0}, {7, -7} },
        damage = dmg,
        sourceEntity = activeItem.ownerEntityId(),
        team = activeItem.ownerTeam(),
        damageSourceKind = "plasma",
        statusEffects = { "aetheri:aethertouched", "paralysis", { effect = "lowgrav", duration = 0.1 } },
        knockback = {0, 42},
        rayCheck = true,
        damageRepeatTimeout = 1,
        damageRepeatGroup = drg,
      }})
      
      local anim = 1.0-math.abs(1.0-v*2.0)--math.sin(v*math.pi)
      anim = math.sin(anim*math.pi*0.5)
      local visMult = anim--^(1/2)
      animator.setPartTag("burst", "directives", string.format("%s?multiply=ffffff%02x", directives, math.floor(0.5 + visMult * 255)))
      animator.resetTransformationGroup("weapon")
      animator.scaleTransformationGroup("weapon", {util.lerp(math.sin(anim*math.pi*0.5), 0, 1.1), util.lerp(anim, 0.5, 0.75)})
      animator.setLightColor("muzzleFlash", color.lightColor(lightColor, anim))
    end
    activeItem.setDamageSources()
    --coroutine.yield()
    
    -- cooldown
    activeItem.setHoldingItem(false)
    dynItem.setAutoAim(true)
    buffered = false
    util.wait((cfg.cooldownTime - cfg.animTime) - script.updateDt())
  else buffered = false end
  
  coroutine.yield()
end end)
