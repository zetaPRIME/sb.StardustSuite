-- "Carbon" theme

function theme.decorate()
  --sb.logInfo("theme decoration called")
  local m = getmetatable('')
  m.blarg = (m.blarg or 0) + 1
  widget.addChild(frame.backingWidget, { type = "label", value = "lol wut " .. m.blarg, position = {0, 0} })
  if m.testSvc then
    m.testSvc.message(nil, nil, "hook through")
  end
  --widget.addChild("layout", { type = "label", value = "lol wut", position = {0, 0} })
end
