-- "Carbon" theme

local mg = metagui
local assets = theme.assets

-- set up some directives
theme.scrollBarDirectives = "?brightness=50?multiply=" .. mg.getColor("accent")

local fw = { }
function theme.decorate()
  mg.widgetContext = fw
  frame.mode = "vertical"
  
  local style = mg.cfg.style
  if (style == "window") then
    frame:addChild { id = "bg", type = "layout", expandMode = {2, 2}, canvasBacked = true, mode = "vertical", spacing = 0, children = {
      { { size = 22 }, 3,
        { id = "icon", type = "image" }, 2,
        { id = "title", type = "label", expand = true, align = "left" }, 2,
        { id = "closeButton", type = "button", caption = "×", captionOffset = {0.5, -0.5}, color = "ff3f3f", size = {13, 13} },
        4
      }
    } }
    
    function fw.closeButton:onClick()
      pane.dismiss()
    end
  else
    frame:addChild { id = "bg", type = "layout", expandMode = {2, 2}, canvasBacked = true }
  end
  frame:updateGeometry() -- kick things to make ninepatch draw correctly the first time
  
  mg.widgetContext = nil
end

function theme.drawFrame()
  c = widget.bindCanvas(fw.bg.subWidgets.canvas)
  c:clear() assets.frame:draw(c)
  
  local style = mg.cfg.style
  if (style == "window") then
    assets.button:draw(c, "accent?multiply=" .. mg.getColor("accent"), {0, frame.size[2] - 22, frame.size[1], frame.size[2]})
    fw.icon.explicitSize = (not mg.cfg.icon) and {0, 0} or nil
    fw.icon:setFile(mg.cfg.icon)
    fw.title:setText(mg.cfg.title)
  end
end

function theme.drawCheckBox(w)
  local c = widget.bindCanvas(w.backingWidget) c:clear()
  local state
  if w.state == "press" then state = "toggle"
  else state = "idle" end
  
  local cstate = "check?multiply=" .. mg.getColor("accent"):sub(1, 6) .. (w.state == "press" and "7f" or (w.checked and "ff" or "00"))
  
  local img = w.radioGroup and assets.radioButton or assets.checkBox
  local pos = vec2.mul(c:size(), 0.5)
  img:draw(c, state, pos)
  img:draw(c, cstate, pos)
end
