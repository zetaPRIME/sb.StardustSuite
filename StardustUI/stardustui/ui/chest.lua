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
  local fSlots = 0
  
  local data = { } -- data cache <descriptor, data>
  local ds = { } -- data sorted
  
  local itms = world.containerItems(id)
  for slot, itm in pairs(itms) do -- assemble data cache
    fSlots = fSlots + 1 -- count up total slots filled
    local has = player.hasCountOfItem(itm, true)
    if has > 0 then
      local d
      for m, dd in pairs(data) do if root.itemDescriptorsMatch(itm, m, true) then d = dd break end end
      if not d then
        d = {
          itm = itm, -- mirror within
          slots = { },
          firstSlot = slot,
          maxStack = metagui.itemMaxStack(itm),
          has = has,
        }
        sb.logInfo("has " .. has .. " " .. itm.name)
        data[itm] = d
        table.insert(ds, d) -- we need to sort this later
      end
      d.slots[slot] = itm.count
    end
  end
  
  fSlots = numSlots - fSlots -- from full slots to free slots
  table.sort(ds, function(a, b) -- true == before
    return a.maxStack > b.maxStack or (a.maxStack == b.maxStack and a.firstSlot < b.firstSlot)
  end)
  
  for ix, d in ipairs(ds) do -- now to actually do the work
    local put = 0
    for s,c in pairs(d.slots) do put = put + (d.maxStack - c) end -- count up how many can be fit in existing stacks
    while put < d.has and fSlots > 0 do -- consume free slots until satisfied
      put = put + d.maxStack
      fSlots = fSlots - 1
    end
    put = math.min(put, d.has) -- clamp to how much we actually have
    local ii = { name = d.itm.name, parameters = d.itm.parameters, count = put }
    player.consumeItem(ii, true, true)
    while put > 0 do -- have to do it stack by stack because Of Course We Do
      ii.count = math.min(put, d.maxStack)
      put = put - ii.count
      world.containerStackItems(id, ii)
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
