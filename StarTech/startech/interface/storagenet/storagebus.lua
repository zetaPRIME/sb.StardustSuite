require "/lib/stardust/sync.lua"

function init()
  sync.poll("getInfo", onRecvInfo)
  widget.focus("filter")
end

function update()
  sync.runQueue()
end

function onRecvInfo(rpc)
  if rpc:succeeded() then
    local res = rpc:result()
    widget.setText("filter", res.filter)
    widget.setText("priority", res.priority .. "")
  end
end

function next(wid)
  widget.focus("priority")
end

function apply()
  sync.msg("setInfo", widget.getText("filter"), tonumber(widget.getText("priority")) or 0)
  pane.dismiss() -- might as well
end
