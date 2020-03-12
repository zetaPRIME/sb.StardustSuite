-- transmatter drive bay, metaGUI edition

require "/lib/stardust/itemutil.lua"

local function waitFor(p) -- wait for promise
  while not p:finished() do coroutine.yield() end
  return p
end

local refreshNow = false
local function refresh() refreshNow = true end
metagui.startEvent(function()
  while true do
    refreshNow = false
    local p = waitFor(world.sendEntityMessage(pane.sourceEntity(), "drivebay:getDisplayItems"))
    local sr = p:succeeded() and p:result()
    if sr then 
      refreshNow = false
      for i = 1, 8 do grid:setItem(i, sr[i] or nil) end
    end
    for i = 1, 30 do
      if refreshNow then break end
      coroutine.yield()
    end
  end
end)

local swapping = false
function grid:onSlotMouseEvent(btn, down)
  if down and btn == 0 then
    if swapping then return true end -- block
    metagui.startEvent(function()
      local item = player.swapSlotItem()
      if item and not itemutil.getCachedConfig(item).config.driveParameters then return nil end -- only accept drives
      player.setSwapSlotItem(nil)
      swapping = true
      local p = waitFor(world.sendEntityMessage(pane.sourceEntity(), "drivebay:swapDrive", player.id(), self.index, item))
      refresh()
      swapping = false
    end)
    
    return true
  end
end

-- TODO: info editing
