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

if not mg.cfg.accentColor or mg.cfg.accentColor == theme.defaultAccentColor then
  mg.cfg.accentColor = color.toHex(color.fromHsl {
    util.randomInRange {0, 1},
    util.randomInRange {0, 1},
    util.randomInRange {0.5, 0.65},
  })
end

local paletteFor do
  local hlAlpha = 0.9 -- 1.0
  local bgAlpha = 0.70
  local glassColors = {
    {"7c50ff", hlAlpha}, -- reference color
    {"a88bff", hlAlpha}, -- highlight
    {"6340cc", hlAlpha}, -- 80
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
    local function ex(v, e) if v < 1.0 then return v^e end return v end -- asymmetrical exponent
    for i = 2, #glassColors do
      local o = glassColors[i]
      local cs = color.toHsl(o[1])
      o[3] = ex(cs[2] / rs[2], satExp)
      o[4] = ex(cs[3] / rs[3], lumExp)
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

function theme.drawButton(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() local pal = paletteFor(w.color or "accent")
  assets.button:draw(c, {w.state or "idle", pal, false and "?multiply=ffffffbf" or nil})
  --[[if w.color == "accent" then
    assets.button:draw(c, "accent" .. pal .. "?multiply=ffffff7f")
  end]]
  theme.drawButtonContents(w)
end
