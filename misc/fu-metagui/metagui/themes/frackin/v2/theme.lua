local mg = metagui

theme._export = { v2 = true }
require "/metagui/themes/frackin/theme.lua"
local color = theme._export.color
local paletteFor = theme._export.paletteFor

local assets = theme.assets
assets.windowBg = "/assetmissing.png" -- clear this out just in case
assets.windowGadget = mg.asset "windowGadget.png"

local fw = theme._export.fw
function theme.drawFrame()
  c = widget.bindCanvas(fw.bg.subWidgets.canvas)
  c:clear()
  
  local pal = paletteFor "accent"
  
  local style = mg.cfg.style
  if (style == "window") then
    local cs = c:size()
    local bgClipWindow = rect.withSize({4, 4}, vec2.sub(cs, {4+6, 4+4}))
    assets.windowBorder:drawToCanvas(c, "frame" .. pal)
    assets.windowBorder:drawToCanvas(c, table.concat {"semi", pal, "?multiply=ffffff3f"})
    c:drawImage(assets.windowGadget .. pal, {5, math.min(math.floor(0.5 + cs[2] * 0.64), cs[2] - 44)}, 1.0, {255,255,255}, true)
    
    theme._adjustFrame()
  else assets.frame:drawToCanvas(c, "default" .. pal) end
end
