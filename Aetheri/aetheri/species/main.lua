-- Aetheri tech override - this one's gonna get *big*
require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"

local bodyReplacePalette = {
  "dafafafa", "caeaeafa", "badadafa", "aacacafa"
}

local function generatePalette(tbl)
  local hue = tbl[1]
  local sat = tbl[2]
  local lumBright = tbl[3]
  local lumDark = tbl[4]
  return {
    color.toHex(color.fromHsl{ hue, sat, lumBright }),
    color.toHex(color.fromHsl{ hue, sat, util.lerp(1/3, lumBright, lumDark) }),
    color.toHex(color.fromHsl{ hue, sat, util.lerp(2/3, lumBright, lumDark) }),
    color.toHex(color.fromHsl{ hue, sat, lumDark })
  }
end

local directives = ""
local updateGlow
local function updateColors()
  local appearance = status.statusProperty("aetheri:appearance", { })
  appearance.coreHsl = appearance.coreHsl or { 0.77, 1, 1.0, 0.64 }
  appearance.palette = generatePalette(appearance.coreHsl)
  appearance.glowColor = color.fromHsl {
    appearance.coreHsl[1],
    appearance.coreHsl[2],
    (appearance.coreHsl[3] + appearance.coreHsl[4]) / 2
  }
  
  status.setStatusProperty("aetheri:appearance", appearance)
  
  local d = {
    "?replace;663b14fe=00000000;8d581cfe=00000000;c88b28fe=00000000;e7c474fe=00000000;404040fe=00000000;808080fe=00000000;6d0103fe=00000000;02da37fe=00000000;5786fffe=00000000",
    color.replaceDirective(bodyReplacePalette, appearance.palette, true),
  }
  directives = table.concat(d)
  tech.setParentDirectives(directives)
  
  playerext.setGlowColor(color.lightColor(appearance.glowColor, 0.64))
  world.sendEntityMessage(entity.id(), "aetheri:paletteChanged")
  updateGlow = true
end

function init()
  updateColors()
  message.setHandler("aetheri:refreshAppearance", updateColors)
end

function update(p)
  if updateGlow then
    updateGlow = false
    local appearance = status.statusProperty("aetheri:appearance", { })
    playerext.setGlowColor(color.lightColor(appearance.glowColor, 0.64))
  end
end















--
