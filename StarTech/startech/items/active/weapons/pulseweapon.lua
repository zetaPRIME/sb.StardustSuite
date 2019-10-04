require "/scripts/util.lua"

require "/lib/stardust/dynitem.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"
require "/lib/stardust/power.item.lua"

--

cfg = (type(cfg) == "table") and cfg or { }
setmetatable(cfg, { __call = util.mergeTable })

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

local function querySelf(cmd, ...)
  return resultOf(world.sendEntityMessage(entity.id(), cmd, ...))
end

energyPal = { "dec2ff", "be5cff", "9711e4" }
local function refreshEnergyColor()
  local pal = querySelf("startech:getEnergyColor")
  if type(pal) == "table" then
    animator.setGlobalTag("energyColor", color.replaceDirective(energyPal, pal))
  else
    animator.setGlobalTag("energyColor", "")
  end
end

function initPulseWeapon()
  cfg.hasFU = root.hasTech("fuhealzone")
  cfg.levelDpsMult = root.evalFunction("weaponDamageLevelMultiplier", config.getParameter("level", 1))
  activeItem.setDamageSources()
  setEnergy(0)
  
  refreshEnergyColor()
  message.setHandler("startech:refreshEnergyColor", refreshEnergyColor)
end

function dmgtype(t) return "electric" .. t end -- visual damage type
function drawPower(amt) return power.drawEquipEnergy(amt, false, 50) >= amt end

do -- energy pulse
  local pulseId = -1
  function cancelPulse() pulseId = (pulseId + 1) % 16384 return pulseId end
  function setEnergy(amt)
    cancelPulse()
    animator.setGlobalTag("energyDirectives", color.alphaDirective(amt))
  end
  function pulseEnergy(amt)
    local id = cancelPulse()
    dynItem.addTask(function()
      for v in dynItem.tween(cfg.pulseTime * amt) do
        if pulseId ~= id then return nil end -- cancel if signaled
        v = math.min((1.0-v) * amt, 1.0) ^ 0.333
        animator.setGlobalTag("energyDirectives", color.alphaDirective(v))
      end
    end)
  end
end
