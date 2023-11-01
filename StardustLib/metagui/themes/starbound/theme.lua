-- Starbound default theme

local mg = metagui
local assets = theme.assets

assets.windowBorder = mg.ninePatch "windowBorder"
assets.buttonColored = mg.ninePatch "buttonColored"

local fw = { }
function theme.decorate()
  mg.widgetContext = fw
  frame.mode = "vertical"
  
  local style = mg.cfg.style
  if (style == "window") then
    frame:addChild { id = "bg", type = "layout", expandMode = {2, 2}, canvasBacked = true, mode = "vertical", spacing = 0, children = {
      2,
      { { spacing = 0, size = 23 },
        5,
        { id = "icon", type = "image" },
        { id = "spacer", type = "spacer", size = 0 },
        { id = "title", type = "label", expand = true, align = "left" },
        { id = "closeButton", type = "iconButton", image = "/interface/x.png", hoverImage = "/interface/xhover.png", pressImage = "/interface/xpress.png" },
        15
      }
    } }
    
    function fw.bg:draw()
      local c = widget.bindCanvas(self.subWidgets.canvas)
      c:clear()
      assets.windowBorder:draw(c, "frame?multiply=" .. mg.getColor("accent"))
      assets.windowBorder:draw(c, "inner")
    end
    
    function fw.closeButton:onClick()
      pane.dismiss()
    end
  else -- raw frame
    frame:addChild { id = "bg", type = "layout", expandMode = {2, 2}, canvasBacked = true, mode = "vertical" }
    function fw.bg:draw()
      local c = widget.bindCanvas(self.subWidgets.canvas)
      c:clear()
      assets.frame:draw(c)
    end
  end
  
  mg.widgetContext = nil
end

function theme.drawFrame()
  local style = mg.cfg.style
  if (style == "window") then
    fw.spacer.explicitSize = (not mg.cfg.icon) and 0 or 3
    fw.icon.explicitSize = (not mg.cfg.icon) and {-1, 0} or nil
    fw.icon:setFile(mg.cfg.icon)
    fw.title:setText("^shadow;" .. mg.cfg.title:gsub('%^reset;', '^reset;^shadow;'))
  end
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
