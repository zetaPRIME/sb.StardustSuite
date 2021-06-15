-- "Carbon" theme

local mg = metagui
local assets = theme.assets

-- set up some directives
theme.scrollBarDirectives = "?brightness=50?multiply=" .. mg.getColor("accent")

local titleBar, icon, title, close
function theme.decorate()
  local style = mg.cfg.style
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
  
  if (style == "window") then
    titleBar = frame:addChild { type = "layout", position = {3, 0}, size = {frame.size[1] - 7, 22}, mode = "horizontal" }
    icon = titleBar:addChild { type = "image" }
    title = titleBar:addChild { type = "label", expand = true, align = "left" }
    close = titleBar:addChild{ type = "button", caption = "×", captionOffset = {0.5, -0.5}, color = "ff3f3f", size = {13, 13} }
    function close:onClick()
      pane.dismiss()
    end
  end
end

function theme.drawFrame()
  local style = mg.cfg.style
  c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  c:clear() assets.frame:draw(c)
  
  if (style == "window") then
    assets.button:draw(c, "accent?multiply=" .. mg.getColor("accent"), {0, frame.size[2] - 22, frame.size[1], frame.size[2]})
    icon.explicitSize = (not mg.cfg.icon) and {0, 0} or nil
    icon:setFile(mg.cfg.icon)
    title:setText(mg.cfg.title)
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
