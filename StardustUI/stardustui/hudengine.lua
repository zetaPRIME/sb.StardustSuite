-- Stardust UI HUD engine (player script)

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
  while true do
    while not inv.isDisplayed() do coroutine.yield() end
    openUI("stardustui:inventory")
    while inv.isDisplayed() do coroutine.yield() end
  end
end)
