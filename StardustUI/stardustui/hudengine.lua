-- Stardust UI HUD engine (player script)

local ipc = getmetatable''["stardustui:"]
if not ipc then ipc = { } getmetatable''["stardustui:"] = ipc end

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
  for _,t in pairs(tasks) do coroutine.resume(t) end
end

function openUI(c)
  player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = c })
end

task(function()
  local inv = interface.bindRegisteredPane "Inventory"
  if inv.getSize()[2] > 0 then -- start of session
    inv.setSize{0, 0}
  end
  while true do
    if inv.isDisplayed() and not ipc.inventoryOpen then
      openUI("stardustui:inventory")
      coroutine.yield() -- need to give it an extra frame to open
    end
    coroutine.yield()
  end
end)
