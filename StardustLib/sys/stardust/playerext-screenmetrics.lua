-- a way to fetch screen metrics

function init()
--function update()
  local c = widget.bindCanvas("c")
  local mp = c:mousePosition()
  sb.logInfo(string.format("mouse pos %f %f", mp[1], mp[2]))
  --sb.logInfo("update called")
  pane.dismiss()
end
