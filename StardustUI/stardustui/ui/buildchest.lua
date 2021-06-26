-- Automatic chest interface

cfg = {
  style = "window",
  scripts = { "chest.lua" },
}


local src = pane.sourceEntity()
local numSlots = world.containerSize(src)

local widths = { 3, 4, 6, 8, 10 }
local slotWidth = 3
for _, n in pairs(widths) do
  if numSlots >= n*n then
    slotWidth = n
  else break end
end
local slotHeight = math.ceil(numSlots / slotWidth)

cfg.size = {
  util.clamp(slotWidth, 4, 10) * 20 - 2,
  util.clamp(slotHeight, 4, 10) * 20 - 2,
}

cfg.children = {
  { type = "scrollArea", expandMode = {2, 2}, children = {
    { id = "itemGrid", type = "itemGrid", slots = numSlots, columns = slotWidth, containerSlot = 1 }
  } },
}

local icfg = root.itemConfig { name = world.entityTypeName(src), parameters = { }, count = 1 }

cfg.icon = util.absolutePath(icfg.directory, world.getObjectParameter(src, "inventoryIcon"))
cfg.title = world.getObjectParameter(src, "shortdescription")
