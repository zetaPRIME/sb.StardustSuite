local function waitFor(p) -- wait for promise
  while not p:finished() do coroutine.yield() end
  return p
end

metagui.startEvent(function() -- sync
  while true do
    local data = waitFor(world.sendEntityMessage(pane.sourceEntity(), "uiSyncRequest")):result()
    if data then
      burnSlot:setItem(data.smelting.item)
      local bsb = burnSlot.subWidgets.slot
      if data.smelting.item.count >= 1 then
        widget.setItemSlotProgress(bsb, ( (data.smelting.remaining or 0) / (data.smelting.smeltTime or 1) ))
      else
        widget.setItemSlotProgress(bsb, 1)
      end
      
      fpLabel:setText(string.format("%i^accent;/^reset;%i^accent;FP^reset;", math.floor(0.5 + (data.batteryStats.energy or 0)), math.floor(0.5 + (data.batteryStats.capacity or 0))))
    end
  end
end)

local recipes = root.itemConfig { name = "startech:autosmelter" }.config.recipes

local blockTakeAll = false
function takeAll:onClick()
  if blockTakeAll then return end
  blockTakeAll = true
  local id = pane.sourceEntity()
  for i = 0, 2 do -- input slots
    local itm = world.containerItemAt(id, i)
    if itm and (not recipes[itm.name] or recipes[itm.name].count > itm.count) then
      player.giveItem(itm)
      world.containerTakeAt(id, i)
    end
  end
  for i = 3, 11 do
    player.giveItem(world.containerItemAt(id, i))
    world.containerTakeAt(id, i)
  end
  for i = 1,15 do coroutine.yield() end
  blockTakeAll = false
end
