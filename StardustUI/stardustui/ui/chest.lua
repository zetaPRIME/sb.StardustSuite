-- Stardust UI chest interface - runtime component

require "/lib/stardust/itemutil.lua"

local src = pane.sourceEntity()

--local slotsBar = slotsLabel
slotsBar.state = "idle"
function slotsBar:isMouseInteractable() return true end
slotsBar.onMouseEnter = metagui.widgetTypes.button.onMouseEnter
slotsBar.onMouseLeave = metagui.widgetTypes.button.onMouseLeave
slotsBar.onMouseButtonEvent = metagui.widgetTypes.button.onMouseButtonEvent
slotsBar.onCaptureMouseMove = metagui.widgetTypes.button.onCaptureMouseMove
function slotsBar:queueRedraw()
  takeAll.state = self.state
  takeAll:queueRedraw()
  if self.state == "idle" then
    slotsLabel:setText(world.containerSize(src) .. " slots")
  else
    local txt = "Take All"
    if self.state == "press" then txt = "^accent;" .. txt end
    slotsLabel:setText(txt)
  end
end

function slotsBar:onClick()
  if not metagui.checkSync(true) then return end
  local id = pane.sourceEntity()
  local numSlots = world.containerSize(id)
  for i = 0, numSlots - 1 do
    player.giveItem(world.containerItemAt(id, i))
    world.containerTakeAt(id, i)
  end
end
function takeAll:isMouseInteractable() return false end

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

function getCompSort(lst)
  return function(a, b)
    local r
    for _,f in pairs(lst) do
      r = f(a,b)
      if r ~= nil then return r end
    end
    return r
  end
end

local rarityNum = {
  common = 1, uncommon = 2, rare = 3, legendary = 4, essential = 100
}

local sc = { }
do
  local function cmp(a, b)
    if a < b then return true end
    if a > b then return false end
    return nil
  end
  
  function sc.rarity(a, b)
    return cmp(b.rarity, a.rarity)
  end
  function sc.name(a, b)
    return cmp(a.sortName, b.sortName)
  end
  function sc.count(a, b)
    return cmp(b.itm.count, a.itm.count)
  end
  function sc.level(a, b)
    return cmp(b.level, a.level)
  end
  function sc.rot(a, b)
    return cmp(b.rot, a.rot)
  end
end

function sort:onClick()
  local id = pane.sourceEntity()
  local itms = world.containerItems(id)
  
  local inf = { }
  for _,itm in pairs(itms) do -- assemble info table
    local e = { itm = itm }
    table.insert(inf, e)
    e.rarity = rarityNum[string.lower(itemutil.property(itm, "rarity"))]
    e.sortName = string.lower(string.gsub(itemutil.property(itm, "shortdescription"), "(^.-;)", ""))
    e.level = itemutil.property(itm, "level") or 0
    e.rot = itm.parameters.timeToRot or 0
  end
  
  local fcmp = getCompSort { sc.rarity, sc.level, sc.name, sc.rot, sc.count }
  table.sort(inf, fcmp)
  
  local fi = { }
  for k,v in pairs(inf) do fi[k] = v.itm end
  
  world.containerTakeAll(id)
  for slot, it in pairs(fi) do world.containerSwapItems(id, it, slot-1) end
end
