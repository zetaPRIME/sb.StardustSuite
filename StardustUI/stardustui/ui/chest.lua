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
  player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = "stardustui:chestoptions", data = { src = src } }, src)
end

do -- mimic ES effect of activating retention on first open
  local keep = world.getObjectParameter(src, "keepContent")
  if keep == nil then world.sendEntityMessage(src, "keepContent", true) end
end
