--

local function waitFor(p) -- wait for promise
  while not p:finished() do coroutine.yield() end
  return p
end

paneBase:updateGeometry()
metagui.startEvent(function()
  local inf = waitFor(world.sendEntityMessage(pane.sourceEntity(), "getInfo")):result()
  filter:setText(inf.filter)
  priority:setText("" .. inf.priority)
  
  filter:focus()
end)

function filter:onEscape() pane.dismiss() end
function filter:onEnter() priority:focus() end
function priority:onEscape() filter:focus() end
function priority:onEnter()
  world.sendEntityMessage(pane.sourceEntity(), "setInfo", filter.text, tonumber(priority.text) or 0)
  pane.dismiss()
end
