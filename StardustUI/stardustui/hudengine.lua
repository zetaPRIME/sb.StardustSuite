-- Stardust UI HUD engine (player script)

require "/lib/stardust/sharedtable.lua"

local ipc = sharedTable "stardustui:ipc"
if not ipc.framecount then ipc.framecount = 0 end

local tasks = { }
function task(f)
  table.insert(tasks, coroutine.create(f))
end

local pInv
function init()
  pInv = interface.bindRegisteredPane "Inventory"
  for _,t in pairs(tasks) do coroutine.resume(t) end
end

function uninit()
  
end

function update()
  ipc.framecount = (ipc.framecount + 1) % 60
  for _,t in pairs(tasks) do coroutine.resume(t) end
end

function openUI(c)
  player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = c })
end

task(function()
  local inv = interface.bindRegisteredPane "Inventory"
  if inv.getSize()[2] > 0 then -- start of session
    
    --for i=1,3 do coroutine.yield() end
    --[[local lp = ((player.getProperty("metagui:state") or { })["/stardustui/ui/inventory.ui"] or { })["metagui:lastPosition"] or {0, 0}
    interface.displayRegisteredPane "Inventory"
    inv.setSize{0, 0}
    inv.setPosition(lp)
    inv.dismiss()]]
    --openUI("stardustui:inventory")
  end
  while true do
    if inv.isDisplayed() and not ipc.inventoryOpen then
      openUI("stardustui:inventory")
      coroutine.yield() -- need to give it an extra frame to open
    end
    coroutine.yield()
  end
end)
