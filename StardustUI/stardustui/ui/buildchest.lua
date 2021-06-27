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

local hasES
local esScripts = {
  ["/scripts/enhancedstorage.lua"] = true,
}
for _,s in pairs(world.getObjectParameter(src, "scripts") or { }) do
  if esScripts[s] then hasES = esScripts[s] break end
end

cfg.size = {
  util.clamp(slotWidth, hasES and 4.25 or 4, 10) * 20 - 2,
  util.clamp(slotHeight, 3, 10.5) * 20 - 2 + 16+2,
}
local overflow = slotHeight > 10

-- only spawn the scroll area when overflow happens
local grid = { id = "itemGrid", type = "itemGrid", slots = numSlots, columns = slotWidth, containerSlot = 1 }
if overflow then
  cfg.size[1] = cfg.size[1] + 4+2 -- compensate for the added width of the panel, plus room for count
  grid = { type = "panel", style = "concave", mode = "vertical", children = { -- and wrap in scrolling
    { type = "scrollArea", expandMode = {2, 2}, children = { grid } },
  } }
end

cfg.children = { { scissoring = false }, -- allow count to slightly overlap window border
  grid,
  { { size = 16 },
    -1, -- tiny bit of space away from edge
    { type = "label", text = numSlots .. " slots" },
    "spacer",
    { id = "esOptions", type = "iconButton", image = "minimenu.png", visible = not not hasES },
    -3, -- slightly less space
    { id = "takeAll", type = "button", caption = "Take All", size = 38, color = "accent" },
  },
}

local icfg = root.itemConfig { name = world.entityTypeName(src), parameters = { }, count = 1 }

local icon = world.getObjectParameter(src, "inventoryIcon")
if type(icon) == "string" then
  cfg.icon = util.absolutePath(icfg.directory, icon)
end
cfg.title = world.getObjectParameter(src, "shortdescription")

local esUIColors = {
  ["?hueshift=-110?saturation=40?brightness=10"] = "d10004", -- red
  ["?hueshift=-80?saturation=80?brightness=35"] = "e49d00", -- orange
  ["?hueshift=-55?saturation=76?brightness=40"] = "e6e000", -- yellow
  --[""] == "59c834", -- green
  ["?hueshift=45?saturation=50?brightness=10"] = "00d197", -- mint
  ["?hueshift=65?saturation=65?brightness=20"] = "00d9d1", -- cyan
  ["?hueshift=88?saturation=50?brightness=14"] = "34c6e2", -- blue
  ["?hueshift=100?saturation=50?brightness=0"] = "0081c8", -- darkblue
  ["?hueshift=155?saturation=20?brightness=15"] = "7900d5", -- purple
  ["?hueshift=180?saturation=40?brightness=15"] = "c100d5", -- pink
}

local guiColor = world.getObjectParameter(src, "guiColor")
cfg.accentColor = esUIColors[guiColor or false]
