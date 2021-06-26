-- Stardust UI chest interface - runtime component

local src = pane.sourceEntity()

function takeAll:onClick()
  if not metagui.checkSync(true) then return end
  local id = pane.sourceEntity()
  local numSlots = world.containerSize(id)
  for i = 0, numSlots - 1 do
    player.giveItem(world.containerItemAt(id, i))
    world.containerTakeAt(id, i)
  end
end

function esOptions:onClick()
  metagui.ipc._stardustui_chestopts = true
  pane.dismiss()
  --player.interact("OpenContainer", nil, src)
  --player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = "stardustui:chestoptions", data = { src = src } }, src)
end

metagui.registerUninit(function()
  if metagui.ipc._stardustui_chestopts then
    player.interact("OpenContainer", nil, src)
  end
end)

do -- mimic ES effect of activating retention on first open
  local keep = world.getObjectParameter(src, "keepContent")
  if keep == nil then world.sendEntityMessage(src, "keepContent", true) end
end
