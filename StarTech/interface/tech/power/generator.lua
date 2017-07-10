--

require "/lib/stardust/sync.lua"

nullItem = { name = "", count = 0, parameters = {} }

function init()
  --
end

syncing = false
function update(dt)
  if not syncing then
    syncing = true
    sync.poll("uiSyncRequest", recvSync)
  end
  sync.runQueue()
end

function recvSync(rpc)
  syncing = false
  if not rpc:succeeded() then return nil end -- failed update
  local data = rpc:result()
  
  -- update burn slot
  widget.setItemSlotItem("burning", data.burning.item or nullItem)
  if data.burning.item.count >= 1 then
    widget.setItemSlotProgress("burning", (data.burning.timeLeft or 0) / (data.burning.fuelTime or 1))
  else
    widget.setItemSlotProgress("burning", 1)
  end
  
  -- and capacitor status
  --widget.setText("batteryStats", table.concat({data.batteryStats.energy or 0, "/", data.batteryStats.capacity or 0, "FP"}))
  widget.setText("batteryStats", string.format("%i^gray;/^reset;%i^gray;FP^reset;", data.batteryStats.energy or 0, data.batteryStats.capacity or 0))
end
