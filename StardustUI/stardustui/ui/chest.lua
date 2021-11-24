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

function quickStack:onClick()
  if not metagui.checkSync(true) then return end
  local id = pane.sourceEntity()
  local numSlots = world.containerSize(id)
  for i = 0, numSlots - 1 do
    local itm = world.containerItemAt(id, i)
    if itm and itm.count > 0 then
      local maxStack = metagui.itemMaxStack(itm)
      local has = player.hasCountOfItem(itm, true)
      local put = has --math.min(maxStack - itm.count, has)
      local fits = world.containerItemsFitWhere(id, itm)
      for k,v in pairs(fits.slots) do
        sb.logInfo("slot " .. k .. " fit " .. v)
      end
      --local rem = world.containerStackItems(id, { name = itm.name, count = put, parameters = itm.parameters })
      --local fit = world.containerItemsCanFit(id, { name = itm.name, count = 1, parameters = itm.parameters })
      --sb.logInfo(itm.name .. ": has " .. has .. " fit " .. fit)
      --sb.logInfo("placed items: " .. (put - (rem and rem.count or 0)))
      --sb.logInfo("put " .. put .. ", rem " .. (rem and rem.count or 0))
      --player.consumeItem({ name = itm.name, count = put - (rem and rem.count or 0), parameters = itm.parameters }, true, true)
    end
  end
end

function esOptions:onClick()
  metagui.ipc._stardustui_chestopts = true
  pane.dismiss()
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
