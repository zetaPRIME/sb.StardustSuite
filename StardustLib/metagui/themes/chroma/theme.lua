-- Chroma theme

require "/lib/stardust/color.lua"

local mg = metagui
local assets = theme.assets

assets.windowBody = mg.ninePatch "windowBody"
assets.titleBarLeft = mg.ninePatch "titleBarLeft"
assets.titleBarRight = mg.ninePatch "titleBarRight"

for _, ast in pairs {
  assets.windowBody, assets.titleBarLeft, assets.titleBarRight,
  assets.frame, assets.panel,
  assets.textBox,
  assets.tabPanel, assets.tab,
  assets.itemSlot,
} do ast.useThemeDirectives = "baseColorDirectives" end

for _, ast in pairs {
  assets.checkBox, assets.radioButton,
  assets.tab,
} do ast.useThemeDirectives = "trimColorDirectives" end

assets.closeButton = mg.extAsset "closeButton"
assets.closeButton.useThemeDirectives = "closeButtonDirectives"
assets.closeButtonSmall = mg.extAsset "closeButtonSmall"
assets.closeButtonSmall.useThemeDirectives = "closeButtonDirectives"

if not mg.cfg.accentColor or mg.cfg.accentColor == theme.defaultAccentColor then
  mg.cfg.accentColor = color.toHex(color.fromHsl {
    util.randomInRange {0, 1},
    util.randomInRange {0.5, 1},
    util.randomInRange {0.5, 0.75},
  })
end

local paletteFor do
  local hlAlpha = 0.9 -- subtle translucency on the highlights
  local bgAlpha = 0.70 -- much clearer glass on anything else
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

theme.baseColorDirectives = paletteFor "accent"
theme.closeButtonDirectives = paletteFor "cc0044"
do
  local hdiff = 3/24
  
  local col = color.toHsl(mg.getColor "accent")
  local h = col[1]
  col[3] = util.clamp(col[3] + 0.2, 0, 1) -- bit brighter
  col[1] = (h + hdiff) % 1.0 -- hue shift
  mg.cfg.accentColor = color.toHex(color.fromHsl(col)) -- set actual accent color
  col[1] = (h - hdiff) % 1.0 -- hue shift
  col = color.fromHsl(col)
  theme.trimColorDirectives = paletteFor(col) -- and now secondary color for unaccented things
  local ac = mg.getColor "accent"
  theme.listItemColorSelected = color.hexWithAlpha(ac, 0.25, true)
  theme.listItemColorSelectedHover = color.hexWithAlpha(ac, 0.5, true)
  
  theme.scrollBarDirectives = paletteFor "accent" .. "?multiply=ffffff7f"
end

local installBg do
  local function bgDraw(self)
    local c = widget.bindCanvas(self.subWidgets.canvas)
    c:clear()
    self._bg:draw(c, self._bgDirectives)
  end
  
  installBg = function(w, bg, directives)
    w._bg = bg
    w._bgDirectives = directives
    w.draw = bgDraw
  end
end

local fw = { } -- frame widgets table
function theme.decorate()
  local style = mg.cfg.style
  
  if style == "window" then
    mg.widgetContext = fw
    
    frame:addChild {
      type = "layout", size = frame.size, mode = "vertical", spacing = 0, children = {
        { -- title bar
          { id = "titleBar", spacing = 0, size = 20 },
          { { id = "titleBarLeft", mode = "horizontal", size = 20, canvasBacked = true, spacing = 2 },
            1,
            { id = "icon", type = "image" },
            { id = "title", type = "label", align = "left", inline = true },
            14,
          },
          { { id = "titleBarRight", mode = "horizontal", size = 20, expandMode = {2, 0}, canvasBacked = true, scissoring = false },
            "spacer", { id = "closeButton", type = "iconButton" },
          },
        },
        { { id = "body", canvasBacked = true, expandMode = {2, 2} } },
      }
    }
    
    installBg(fw.titleBarLeft, assets.titleBarLeft)
    installBg(fw.titleBarRight, assets.titleBarRight)
    installBg(fw.body, assets.windowBody)
    
    --fw.closeButton:setImage(assets.closeButton)
    fw.closeButton.onClick = pane.dismiss
    
    mg.widgetContext = nil
  else
    widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
  end
end

function theme.drawFrame()
  local style = mg.cfg.style
  
  if (style == "window") then
    fw.icon.explicitSize = (not mg.cfg.icon) and {0, 0} or nil
    fw.icon:setFile(mg.cfg.icon)
    fw.title:setText(mg.cfg.title)
    
    local fitClose = frame.size[1] - fw.titleBarLeft:preferredSize()[1] >= 20
    fw.closeButton:setImage(fitClose and assets.closeButton or assets.closeButtonSmall)
    --fw.closeButton:setVisible(fitClose)
    fw.titleBarRight.explicitSize = (not fitClose) and {2, 20} or nil
    fw.titleBarRight.expandMode = (not fitClose) and {0, 0} or {2, 0}
    --[[mg.startEvent(function()
    coroutine.yield()
      fw.titleBarRight:updateGeometry()
    end)]]
  else
    c = widget.bindCanvas(frame.backingWidget .. ".canvas")
    c:clear() assets.frame:draw(c)
  end
end

function theme.drawButton(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() local pal = w.color and paletteFor(w.color) or theme.trimColorDirectives
  assets.button:draw(c, {w.state or "idle", pal, false and "?multiply=ffffffbf" or nil})
  --[[if w.color == "accent" then
    assets.button:draw(c, "accent" .. pal .. "?multiply=ffffff7f")
  end]]
  theme.drawButtonContents(w)
end

function theme.drawCheckBox(w)
  local c = widget.bindCanvas(w.backingWidget) c:clear()
  local state
  if w.state == "press" then state = { "toggle", "?multiply=dfdfdf" and nil }
  else state = "idle" end
  
  local cstate = { "check", "?multiply=ffffff", w.state == "press" and "7f" or (w.checked and "ff" or "00") }
  
  local img = w.radioGroup and assets.radioButton or assets.checkBox
  local pos = vec2.mul(c:size(), 0.5)
  img:draw(c, state, pos)
  img:draw(c, cstate, pos)
end

local rarityColors = {
  common    = "f6f6f6",
  uncommon  = "42c53e",
  rare      = "3ea8c5",
  legendary = "893ec5",
  essential = "c3c53e",
}
for k,v in pairs(rarityColors) do -- adjust brightness
  local hsl = color.toHsl(v)
  hsl[3] = util.clamp(hsl[3], 0.525, 0.8)
  rarityColors[k] = color.toHex(color.fromHsl(hsl))
end

function theme.drawItemSlot(w)
  local center = {9, 9}
  local c = widget.bindCanvas(w.backingWidget)
  c:clear() assets.itemSlot:draw(c, w.hover and "hover" or "idle", center)
  if w.glyph then
    if w.colorGlyph then
      c:drawImage(w.glyph, center, nil, nil, true)
    else
      c:drawImage(w.glyph .. theme.itemSlotGlyphDirectives, center, nil, nil, true)
    end
  end
  local ic = root.itemConfig(w:item())
  if ic and not w.hideRarity then
    local hover = w.hover or not w:isMouseInteractable() -- always full brightness if can't recieve hover
    local rarity = (ic.parameters.rarity or ic.config.rarity or "Common"):lower()
    local directives = {"default", paletteFor(rarityColors[rarity]), "?multiply=ffffffdf", false and hover and "?brightness=25" or nil}
    local passes = hover and 3 or 1
    for i = 1,passes do assets.itemRarity:draw(c, directives, center) end -- reinforce opacity when highlighted
  end
end
