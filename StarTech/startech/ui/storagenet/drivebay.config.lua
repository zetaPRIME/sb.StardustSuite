local ipc = metagui.ipc["startech:drivebay.config"]

function update()
  if metagui.ipc["startech:drivebay.config"] ~= ipc then return pane.dismiss() end
end

function uninit()
  -- clean up
  if metagui.ipc["startech:drivebay.config"] == ipc then metagui.ipc["startech:drivebay.config"] = nil end
end


function filter:onEscape() pane.dismiss() end
function filter:onEnter() priority:focus() end
function priority:onEscape() filter:focus() end
function priority:onEnter()
  ipc.apply(ipc.slot, filter.text, tonumber(priority.text))
  pane.dismiss()
end

function init()
  paneBase:updateGeometry()
  filter:setText(ipc.filter)
  priority:setText("" .. ipc.priority)
  
  filter:focus()
end
