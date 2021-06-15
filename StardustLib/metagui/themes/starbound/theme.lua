-- Starbound default theme

local mg = metagui
local assets = theme.assets

assets.windowBorder = mg.ninePatch "windowBorder"
assets.buttonColored = mg.ninePatch "buttonColored"

local titleBar, icon, title, close, spacer
function theme.decorate()
  local style = mg.cfg.style
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
  
  if (style == "window") then
    titleBar = frame:addChild { type = "layout", position = {5, 2}, size = {frame.size[1] - 24 - 5, 23}, mode = "horizontal" }
    icon = titleBar:addChild { type = "image" }
    spacer = titleBar:addChild { type = "spacer", size = 0 }
    spacer.expandMode = {0, 0}
    title = titleBar:addChild { type = "label", expand = true, align = "left" }
    close = frame:addChild{
      type = "iconButton", position = {frame.size[1] - 24, 8},
      image = "/interface/x.png", hoverImage = "/interface/xhover.png", pressImage = "/interface/xpress.png"
    }
    function close:onClick()
      pane.dismiss()
    end
  end
end

function theme.drawFrame()
  local style = mg.cfg.style
  c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  c:clear() --assets.frame:draw(c)
  
  if (style == "window") then
    assets.windowBorder:draw(c, "frame?multiply=" .. mg.getColor("accent"))
    assets.windowBorder:draw(c, "inner")
    
    spacer.explicitSize = (not mg.cfg.icon) and -2 or 1
    icon.explicitSize = (not mg.cfg.icon) and {-1, 0} or nil
    icon:setFile(mg.cfg.icon)
    title:setText("^shadow;" .. mg.cfg.title:gsub('%^reset;', '^reset;^shadow;'))
  else assets.frame:draw(c) end
end

function theme.drawButton(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear()
  local acc = mg.getColor(w.color)
  if acc then
    assets.buttonColored:draw(c, (w.state or "idle") .. "?multiply=" .. acc)
  else
    assets.button:draw(c, w.state or "idle")
  end
  theme.drawButtonContents(w)
end
