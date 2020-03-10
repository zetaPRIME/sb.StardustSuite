-- "Carbon" theme

require "/scripts/rect.lua"

local mg = metagui

local npFrame = mg.ninePatch(asset "frame")

local c
local dw = "debugWidget"

function theme.decorate()
  --sb.logInfo("theme decoration called")
  local m = getmetatable('')
  m.blarg = (m.blarg or 0) + 1
  --widget.addChild(frame.backingWidget, { type = "label", value = "lol wut " .. m.blarg, position = {0, 0} })
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size, captureMousseEvents = true, clickCallback = "canvasTest" }, "canvas")
  c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  npFrame:drawToCanvas(c)
  
  pane.addWidget({ type = "label" }, dw)
  
  --if m.testSvc then m.testSvc.message(nil, nil, "hook through " .. m.blarg) end
  --widget.addChild("layout", { type = "label", value = "lol wut", position = {0, 0} })
  --pane.playSound("/sfx/interface/inventory_pickup1.ogg")
  
  --sb.logInfo(util.tableToString(_ENV))
end

function theme.drawButton(b)
  local c = widget.bindCanvas(b.backingWidget)
  c:clear()
  npFrame:drawToCanvas(c)
  c:drawText(b.caption or "", { position = vec2.mul(c:size(), 0.5), horizontalAnchor = "mid", verticalAnchor = "mid", wrapWidth = b.size[1] - 4 }, 8)
end

function supdate(...)
  local mp = c:mousePosition()
  --sb.logInfo(util.tableToString{...})
  widget.setText(dw, table.concat {
    "mouse pos ", mp[1], ", ", mp[2], "; over: ", (widget.getChildAt(mp) or "nothing"),
    "\ncorner overlap: ", widget.inMember(frame.backingWidget .. ".canvas", {0, 0}) and "true" or "false"
  })
end

function createTooltip(pos)
  --[[widget.setText(dw, table.concat {
    "mouse pos ", pos[1], ", ", pos[2],
    "\nwindow pos ", mg.windowPosition[1], ", ", mg.windowPosition[2],
  })]]
  
  --local m = getmetatable('')
  --if m.testSvc then m.testSvc.message(nil, nil, "ctt pos " .. pos[1] .. ", " .. pos[2] .. "; over: " .. (widget.getChildAt(pos) or "nothing")) end
  --pane.playSound("/sfx/interface/actionbar_select.ogg")
end
