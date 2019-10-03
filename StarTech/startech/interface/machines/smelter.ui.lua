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
  widget.setItemSlotItem("smelting", data.smelting.item or nullItem)
  if data.smelting.item.count >= 1 then
    widget.setItemSlotProgress("smelting", 1 - ( (data.smelting.remaining or 0) / (data.smelting.smeltTime or 1) ))
  else
    widget.setItemSlotProgress("smelting", 1)
  end
  
  -- and capacitor status
  widget.setText("batteryStats", string.format("%i^gray;/^reset;%i^gray;FP^reset;", math.floor(0.5 + (data.batteryStats.energy or 0)), math.floor(0.5 + (data.batteryStats.capacity or 0))))
end
