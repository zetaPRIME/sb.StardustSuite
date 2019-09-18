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
  
  animator.setPartTag("wave", "partImage", "/aetheri/skills/wave.png")
  animator.setPartTag("wave", "directives", "?multiply=ffffff00")
  animator.setLightColor("muzzleFlash", color.lightColor(lightColor, 0))
  
  activeItem.setDamageSources()
  
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
  
  animTime = 1/3,
  distance = 30,
  
  altManaCost = 12,
  altBaseDamage = 7,
}

local buffered = false

-- buffer task
dynItem.addTask(function() while true do
  if dynItem.firePress then buffered = 1 elseif dynItem.altFirePress then buffered = 2 end
  
  coroutine.yield()
end end)

function addPoly(pos, poly)
  poly = util.mergeTable({ }, poly)
  for k, v in pairs(poly) do
    poly[k] = vec2.add(pos, v)
  end
  return poly
end

function capsuleSweep(p1, p2, size)
  if p1 > p2 then local p = p1 p1 = p2 p2 = p end
  local d = math.sqrt(2)/2
  
  return {
    { p1, size },
    { p1 - size*d, size*d },
    { p1 - size, 0 },
    { p1 - size*d, -size*d },
    { p1, -size },
    { p2, -size },
    { p2 + size*d, -size*d },
    { p2 + size, 0 },
    { p2 + size*d, size*d },
    { p2, size },
  }
end

local function enc(stat)
  return "::" .. sb.printJson(stat)
end

-- fire task
dynItem.addTask(function() while true do
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
end end)
