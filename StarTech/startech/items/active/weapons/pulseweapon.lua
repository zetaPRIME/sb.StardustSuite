require "/scripts/util.lua"

require "/lib/stardust/dynitem.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"
require "/lib/stardust/power.item.lua"

require "/sys/stardust/skilltree/calc.lua"

--

do
  cfg = (type(cfg) == "table") and cfg or { }
  stats = (type(stats) == "table") and stats or { }
  flags = (type(flags) == "table") and flags or { }
  local mt = { __call = util.mergeTable }
  setmetatable(cfg, mt) setmetatable(stats, mt)
end

cfg { -- defaults
  baseDps = 15,
  basePowerDraw = 1000, -- per second per 100% damage
}

stats { -- default stats
  damage = 1.0,
  speed = 1.0,
  charge = 1.0,
  accuracy = 1.0,
  punchthrough = 0.0,
}

function assetPath(s) cfg.assetPath = s end
function assetPrefix(s) cfg.assetPrefix = s end
function asset(s) return string.format("%s%s%s.png", cfg.assetPath or "", cfg.assetPrefix or "", s) end
function assetRaw(s) return string.format("%s%s.png", cfg.assetPath or "", s) end
assetPath "/startech/items/active/weapons/"
assetPrefix ""

local function resultOf(promise)
  err = nil
  if not promise:finished() then return promise end
  if not promise:succeeded() then
    err = promise:error()
    return nil
  end
  return promise:result()
end

function querySelf(cmd, ...)
  return resultOf(world.sendEntityMessage(entity.id(), cmd, ...))
end

energyParams = { "", "" }
energyPal = { "dec2ff", "be5cff", "9711e4" }
local function refreshEnergyColor()
  local pal = querySelf("startech:getEnergyColor")
  if type(pal) == "table" then
    local p = color.replaceDirective(energyPal, pal)
    energyParams[1] = p
    animator.setGlobalTag("energyColor", p)
  else
    energyParams[1] = ""
    animator.setGlobalTag("energyColor", "")
  end
end

function initPulseWeapon()
  cfg.hasFU = root.hasTech("fuhealzone")
  --cfg.levelDpsMult = root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))
  activeItem.setDamageSources()
  setEnergy(0)
  
  cfg.baseStatus = {
    weaponUtil.dmgTypes { fire = 1, electric = 1 },
    weaponUtil.tag "antiSpace",
  }
  
  local skillData = config.getParameter("stardustlib:skillData")
  local stat = skillData and skillData.stats
  if stat then
    for k,v in pairs(stat) do stats[k] = skilltree.calculateFinalStat(v) end
  end
  util.mergeTable(flags, skillData and skillData.flags or { })
  
  refreshEnergyColor()
  message.setHandler("startech:refreshEnergyColor", refreshEnergyColor)
end

function dmgtype(t) return "electric" .. t end -- visual damage type
function drawPower(amt) return power.drawEquipEnergy(amt, false, 50) >= amt end
function baseStatus() return table.unpack(cfg.baseStatus) end
function damage(m) return m * (cfg.baseDps or 1.0) * stats.damage * status.stat("powerMultiplier", 1.0) end
-- draw power for a given proportion of DPS - take own damage multiplier (power output) into account but not armor bonus
function drawPowerFor(m) return drawPower(m * cfg.basePowerDraw * stats.damage) end

do -- energy pulse
  local pulseId = -1
  function cancelPulse() pulseId = (pulseId + 1) % 16384 return pulseId end
  function setEnergy(amt)
    cancelPulse()
    local p = color.alphaDirective(amt)
    energyParams[2] = p
    animator.setGlobalTag("energyDirectives", p)
  end
  function pulseEnergy(amt)
    local id = cancelPulse()
    dynItem.addTask(function()
      for v in dynItem.tween(cfg.pulseTime * amt) do
        if pulseId ~= id then return nil end -- cancel if signaled
        v = math.min((1.0-v) * amt, 1.0) ^ 0.333
        local p = color.alphaDirective(v)
        energyParams[2] = p
        animator.setGlobalTag("energyDirectives", p)
      end
    end)
  end
end

-- some geometry utilities

function spread(angle, range, exp)
  if not range or range == 0 then return angle end
  local r = math.random()*2-1
  r = math.abs(r)^(exp or 1) * (r >= 0 and 1 or -1)
  return angle + r*range
end

function polyFan(width, rad, pts)
  local p = {{0, 0}}
  pts = pts or 7
  for i = 1, pts do
    table.insert(p, vec2.rotate({rad, 0}, (2 * ((i-1)/(pts-1)) - 1) * width))
  end
  return p
end

-- and the failure state for combos
function fail() -- not enough fp
  pulseEnergy(0.5) -- "attempt" to power up
  animator.stopAllSounds("fail")
  animator.playSound("fail")
end
