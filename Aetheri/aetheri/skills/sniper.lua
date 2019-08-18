require "/lib/stardust/dynItem.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"


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
  
  animator.setPartTag("beam", "partImage", "/aetheri/skills/sniperbeam.png")
  animator.setPartTag("beam", "directives", "?multiply=ffffff00")
  
  updateColors()
  message.setHandler("aetheri:paletteChanged", updateColors)
  dynItem.install()
  dynItem.setAutoAim(true)
end

function uninit()
  --
end

local cfg = {
  manaCost = 70,
  
  chargeTime = 5.0,
  minimumCharge = 0.1,
  
  damageRange = {10, 150},
  damageCurve = 2.0,
  
  chargeBonus = 1.5,
}

local busy = false
function fireTask()
  if busy then return nil end
  busy = true
  
  dynItem.setAutoAim(true)
  
  animator.setSoundVolume("charge", 0.0, 0)
  animator.playSound("charge", -1)
  
  animator.setPartTag("flash", "partImage", "/aetheri/skills/orb.png")
  animator.setPartTag("flash", "directives", directives)
  
  local chargeLevel = 0
  local bonus = false
  local osc = coroutine.wrap(function()
    local set = {1.0, 0.75, 0.5}
    local i, n = 0, #set
    while true do
      coroutine.yield(set[i+1])
      i = (i + 1) % n
    end
  end)
  local flip = coroutine.wrap(function()
    local f = true
    while true do
      coroutine.yield(f and 1.0 or -1.0)
      f = not f
    end
  end)
  
  while dynItem.fire do
    local ocl = chargeLevel
    chargeLevel = math.min(chargeLevel + script.updateDt() / cfg.chargeTime, math.min(status.resource("aetheri:mana") / cfg.manaCost, 1.0))
    if chargeLevel == 1.0 and ocl < 1.0 then
      bonus = true
      animator.playSound("bonus")
      dynItem.addTask(function() util.wait(0.2) bonus = false end)
    end
    
    animator.setSoundPitch("charge", util.lerp(chargeLevel^2, 0.5, 4.0), 0)
    animator.setSoundVolume("charge", math.min(chargeLevel / cfg.minimumCharge, 1.0), 0)
    
    local out = math.min(chargeLevel / cfg.minimumCharge, 1) ^ 0.125
    animator.resetTransformationGroup("flash")
    animator.scaleTransformationGroup("flash", util.lerp(chargeLevel, 0.25, 1.0) * osc())
    animator.scaleTransformationGroup("flash", out)
    animator.translateTransformationGroup("flash", {chargeLevel * 0.75, 0})
    animator.translateTransformationGroup("flash", {2 - 1.32, (1.0-out) * 3 * flip()})
    
    if chargeLevel == 1.0 then
      if bonus then activeItem.setCursor("/cursors/chargeready.cursor")
      else activeItem.setCursor("/cursors/chargeinvalid.cursor") end
    else
      local a = math.floor((1.0 - chargeLevel) * 7)
      if a < 1 then activeItem.setCursor("/cursors/chargeidle.cursor")
      else activeItem.setCursor(string.format("/cursors/reticle%i.cursor", a-1)) end
    end
    
    activeItem.setHoldingItem(true)
    coroutine.yield()
  end
  
  animator.stopAllSounds("charge")
  
  animator.scaleTransformationGroup("flash", 0)
  
  if chargeLevel >= cfg.minimumCharge then
    local bns = bonus
    status.overConsumeResource("aetheri:mana", cfg.manaCost * chargeLevel)
    
    animator.setSoundVolume("fire", util.lerp(chargeLevel, 0.75, 1.0))
    animator.playSound("fire")
    if bns then
      animator.setSoundPitch("bonusFire", 0.75)
      animator.playSound("bonusFire")
    end
    
    local damage = util.lerp(((chargeLevel - cfg.minimumCharge) / (1.0 - cfg.minimumCharge)) ^ cfg.damageCurve, cfg.damageRange[1], cfg.damageRange[2])
    if bns then damage = damage * cfg.chargeBonus end
    local dmg = damage * status.stat("powerMultiplier", 1.0) * status.stat("aetheri:skillPowerMultiplier", 0.0)
    local line = dynItem.offsetPoly{ {0, 0}, {150, 0} }
    activeItem.setDamageSources({{
      line = line,
      damage = dmg,
      trackSourceEntity = true,
      sourceEntity = activeItem.ownerEntityId(),
      team = activeItem.ownerTeam(),
      damageSourceKind = "plasma",
      statusEffects = { "aetheri:aethertouched" },
      knockback = 22,
      rayCheck = true,
      damageRepeatTimeout = 0,
    }})
    
    local beamSize = bns and 0.75 or 0.5
    activeItem.setCursor("/cursors/chargeidle.cursor")
    
    dynItem.addTask(function()
      local pos = vec2.add(mcontroller.position(), {0, 0})
      line = {vec2.add(pos, line[1]), vec2.add(pos, line[2])}
      line[2] = world.lineCollision(line[1], line[2]) or line[2]
      local dist = vec2.mag(vec2.sub(line[1], line[2]))
      
      local d, a = dynItem.aimDir, dynItem.aimAngle
      for v in dynItem.tween(1.0, 0.0, 0.15) do
        activeItem.setHoldingItem(true)
        dynItem.aimAt(d, a)
        activeItem.setOutsideOfHand(d < 0)
        
        animator.setPartTag("beam", "directives", string.format("%s?multiply=ffffff%02x", directives, math.floor(0.5 + v * 255)))
        animator.resetTransformationGroup("beam")
        animator.scaleTransformationGroup("beam", {dist*8.0, beamSize * v^2})
        
        if not busy then
          local a = math.min(math.floor((1.0-v) * 6), 5)
          activeItem.setCursor(string.format("/cursors/reticle%i.cursor", a))
        end
      end
    end)
    
    coroutine.yield()
    activeItem.setDamageSources()
  end
  
  busy = false
end

function update()
  --sb.logInfo("tick")
  activeItem.setHoldingItem(false)
  activeItem.setCursor("/cursors/reticle5.cursor")
  if dynItem.firePress then dynItem.addTask(fireTask) end
end

--status.consumeResource("aetheri:mana", cost)
--activeItem.setFrontArmFrame((anim < 0.32) and "run.3" or "rotation")
--activeItem.setBackArmFrame((anim < 0.32) and "jump.3" or "rotation")
