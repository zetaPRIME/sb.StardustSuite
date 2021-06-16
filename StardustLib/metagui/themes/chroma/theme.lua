-- Chroma theme

require "/lib/stardust/color.lua"

local mg = metagui
local assets = theme.assets

for _, ast in pairs {
  assets.frame, assets.panel,
  assets.textBox,
  assets.tabPanel, assets.tab,
  assets.checkBox, assets.radioButton,
  assets.itemSlot,
} do ast.useThemeDirectives = "primaryDirectives" end
--theme.primaryDirectives = "?multiply=" .. mg.getColor "accent" .. "?brightness=75?multiply=ffffffbf"
theme.primaryDirectives = "?multiply=ffffffbf"

local paletteFor do
  local bgAlpha = 0.75
  local glassColors = {
    {"7c50ff", 1.0}, -- reference color
    {"a88bff", 1.0}, -- highlight
    {"6340cc", 1.0}, -- 80
    {"4e32a3", bgAlpha}, -- 64
    {"322066", bgAlpha}, -- 40
    {"1f1440", bgAlpha}, -- 25
    {"120d20", bgAlpha}, -- 12.5
  }
  local glassPalette = { } for k,v in pairs(glassColors) do glassPalette[k] = v[1] end
  
  -- shading depths
  local satExp = 1.0
  local lumExp = 1.25 -- 1.25
  do -- calculate relative sat and lum values
    glassColors[1][3] = 1.0
    glassColors[1][4] = 1.0
    local rs = color.toHsl(glassColors[1][1])
    for i = 2, #glassColors do
      local o = glassColors[i]
      local cs = color.toHsl(o[1])
      o[3] = (cs[2] / rs[2]) ^ satExp
      o[4] = (cs[3] / rs[3]) ^ lumExp
    end
  end
  
  local palettes = { }
  paletteFor = function(col)
    col = mg.getColor(col)
    if palettes[col] then return palettes[col] end
    
    local h, s, l = table.unpack(color.toHsl(col))
    local function c(v) return util.clamp(v, 0, 1) end
    local cl = { } -- color list
    for i = 1, #glassColors do
      local o = glassColors[i]
      cl[i] = color.fromHsl { h, c(s * o[3]), c(l * o[4]), o[2] }
    end
    local pal = { color.replaceDirective(glassPalette, cl) }
    
    pal = table.concat(pal)
    palettes[col] = pal
    return pal
  end
end

theme.primaryDirectives = paletteFor "accent"
