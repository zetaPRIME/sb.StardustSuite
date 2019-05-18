-- handles all appearance and animation apart from the HUD

require "/lib/stardust/color.lua"

appearance = {
  baseDirectives = "",
}

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
function appearance.updateColors()
  appearance.settings = status.statusProperty("aetheri:appearance", { })
  local a = appearance.settings
  if not a.coreHsl then
    local name = world.entityName(entity.id())
    a.coreHsl = { -- start with a randomized core color based on your name!
      sb.staticRandomDoubleRange(0.0, 1.0, name, "core hue"), -- random hue
      1.0 - sb.staticRandomDoubleRange(0.0, 1.0, name, "core saturation")^2, -- biased toward saturated
      math.min(1, sb.staticRandomI32Range(0, 4, name, "bright or dark?")), -- 1 in 5 chance to start dark
      sb.staticRandomDoubleRange(0.3, 0.7, name, "border brightness")
    }
    --playerext.message("generated values: " .. util.tableToString(a.coreHsl))
  end
  a.palette = generatePalette(a.coreHsl)
  a.glowColor = color.fromHsl {
    a.coreHsl[1],
    a.coreHsl[2],
    0.5 + (((a.coreHsl[3] + a.coreHsl[4]) / 2) - 0.5) * 0.5 -- average luma, pushed towards 0.5 (full vivid)
  }
  
  status.setStatusProperty("aetheri:appearance", a)
  
  local d = {
    "?replace;663b14fe=00000000;8d581cfe=00000000;c88b28fe=00000000;e7c474fe=00000000;404040fe=00000000;808080fe=00000000;6d0103fe=00000000;02da37fe=00000000;5786fffe=00000000",
    color.replaceDirective(bodyReplacePalette, a.palette, true),
  }
  appearance.baseDirectives = table.concat(d)
  tech.setParentDirectives(appearance.baseDirectives)
  
  playerext.setGlowColor(color.lightColor(a.glowColor, 0.8))
  world.sendEntityMessage(entity.id(), "aetheri:paletteChanged")
  updateGlow = true
end

function appearance.update(p)
  if updateGlow then
    updateGlow = false
    local a = appearance.settings
    playerext.setGlowColor(color.lightColor(a.glowColor, 0.8))
  end
end

-- register these here since this is executed during techstub init
message.setHandler("aetheri:refreshAppearance", appearance.updateColors)
