require "/lib/stardust/sync.lua"
require "/lib/stardust/itemutil.lua"

local xs = {
  syncTime = 0
}

function init()
  --
end

function update()
  sync.runQueue()
  
  if xs.syncRpc and xs.syncRpc:finished() then
    local sr = xs.syncRpc:succeeded() and xs.syncRpc:result()
    xs.syncTime = 30 -- half a second
    xs.syncRpc = nil
    if sr then 
      local i
      for i = 1, 8 do
        widget.setItemSlotItem("slot_"..i, sr[i] or nil)
      end
    end
  end
  if xs.syncTime == 0 then
    xs.syncRpc = world.sendEntityMessage(pane.sourceEntity(), "drivebay:getDisplayItems")
  end
  xs.syncTime = xs.syncTime - 1
  
  if xs.swapRpc and xs.swapRpc:finished() then
    xs.swapRpc = nil
    
    -- force sync
    xs.syncRpc = world.sendEntityMessage(pane.sourceEntity(), "drivebay:getDisplayItems")
    xs.syncTime = -1
  end
end

function getSlotNum(n) return tonumber(string.match(n, '_(.-)$')) end
function slotL(n) slotClicked(getSlotNum(n)) end
function slotR(n) slotClicked(getSlotNum(n), true) end

function slotClicked(slot, right)
  if right then return nil end -- block for now
  if xs.swapRpc then return nil end -- also block on pending swap
  local item = player.swapSlotItem()
  if item and not itemutil.getCachedConfig(item).config.driveParameters then return nil end -- only accept drives
  xs.swapRpc = world.sendEntityMessage(pane.sourceEntity(), "drivebay:swapDrive", player.id(), slot, item)
  player.setSwapSlotItem(nil)
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
