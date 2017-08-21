require "/lib/stardust/sync.lua"

function init()
  --
end

function update()
  sync.runQueue()
end

function onRecvInfo(rpc)
  if rpc:succeeded() then
    local res = rpc:result()
    if not res then return nil end
    selSlot = res.slot
    widget.setText("filter", res.filter)
    widget.setText("priority", res.priority .. "")
    
    widget.focus("filter")
  end
end

selSlot = false
selectTarget = {
  select_1 = 1, select_2 = 2,
  select_3 = 3, select_4 = 4,
  select_5 = 5, select_6 = 6,
  select_7 = 7, select_8 = 8
}
function select(wid)
  local slot = selectTarget[wid]
  sync.poll("getInfo", onRecvInfo, slot)
end

function next(wid)
  widget.focus("priority")
end

function apply()
  widget.blur("priority")
  if not selSlot then return nil end
  sync.msg("setInfo", selSlot, widget.getText("filter"), tonumber(widget.getText("priority")) or 0)
  selSlot = false
  widget.setText("filter", "")
  widget.setText("priority", "")
end
