-- "Carbon" theme

require "/scripts/rect.lua"

local mg = metagui

local npFrame = mg.ninePatch(asset "frame")
local npButton = mg.ninePatch(asset "button")

local c
local dw = "debugWidget"

function theme.decorate()
  local style = mg.cfg.style
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
  
  if (style == "window") then
    local csize = 14
    local csub = 0
    local close = frame:addChild({ type = "button", caption = "×", captionOffset = {0.5, -0.5}, color = "ff3f3f", size = {csize-csub*2, csize-csub*2}, position = {frame.size[1] - csize - 3 + csub, 3 + csub} })
    function close:onClick() paneBase:clearChildren() close:delete() end --pane.dismiss() end
  end
  
end

function theme.drawFrame()
  local style = mg.cfg.style
  c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  c:clear() npFrame:drawToCanvas(c)
  
  if (style == "window") then
    npButton:drawToCanvas(c, "accent?multiply=" .. mg.getColor("accent"), {0, frame.size[2] - 22, frame.size[1], frame.size[2]})
    c:drawText(mg.cfg.title or "", { position = {6, frame.size[2] - 6}, horizontalAnchor = "left", verticalAnchor = "top" }, 8)
  end
end

function theme.drawButton(b)
  local c = widget.bindCanvas(b.backingWidget)
  c:clear() npButton:drawToCanvas(c, b.state or "idle")
  local acc = mg.getColor(b.color)
  if acc then npButton:drawToCanvas(c, "accent?multiply=" .. acc) end
  c:drawText(b.caption or "", { position = vec2.add(vec2.mul(c:size(), 0.5), b.captionOffset), horizontalAnchor = "mid", verticalAnchor = "mid", wrapWidth = b.size[1] - 4 }, 8)
end

function theme.onButtonHover(b)
  pane.playSound("/sfx/interface/hoverover_bumb.ogg", 0, 0.75)
end

function theme.onButtonClick(b)
  pane.playSound("/sfx/interface/clickon_success.ogg", 0, 1.0)
end
