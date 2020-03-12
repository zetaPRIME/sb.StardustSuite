-- "Carbon" theme

require "/metagui/themes/theme-common.lua"

local mg = metagui
local assets = theme.assets

function theme.decorate()
  local style = mg.cfg.style
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
  
  if (style == "window") then
    local csize, csub = 14, 0
    local close = frame:addChild({ type = "button", caption = "×", captionOffset = {0.5, -0.5}, color = "ff3f3f", size = {csize-csub*2, csize-csub*2}, position = {frame.size[1] - csize - 3 + csub, 3 + csub} })
    function close:onClick()
      pane.dismiss()
    end
  end
end

function theme.drawFrame()
  local style = mg.cfg.style
  c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  c:clear() assets.frame:drawToCanvas(c)
  
  if (style == "window") then
    assets.button:drawToCanvas(c, "accent?multiply=" .. mg.getColor("accent"), {0, frame.size[2] - 22, frame.size[1], frame.size[2]})
    c:drawText(mg.formatText(mg.cfg.title) or "", { position = {6, frame.size[2] - 6}, horizontalAnchor = "left", verticalAnchor = "top" }, 8)
  end
end
