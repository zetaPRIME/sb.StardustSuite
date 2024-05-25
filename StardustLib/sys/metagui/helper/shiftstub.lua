-- simple activeitem stub to allow checking for shift+click
require "/lib/stardust/sharedtable.lua"
local ipc = sharedTable "metagui:ipc"

function init() activeItem.setHoldingItem(false) end
function update(_, _, shift)
  player.setSwapSlotItem(config.getParameter("restore"))
  ipc.shiftCheck(shift)
end
