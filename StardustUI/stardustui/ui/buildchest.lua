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
  util.clamp(slotHeight, 3, 10.5) * 20 - 2 + 16+2,
}

local hasES
local esScripts = {
  ["/scripts/enhancedstorage.lua"] = true,
}
for _,s in pairs(world.getObjectParameter(src, "scripts") or { }) do
  if esScripts[s] then hasES = esScripts[s] break end
end

cfg.children = {
  { type = "scrollArea", expandMode = {2, 2}, children = {
    { id = "itemGrid", type = "itemGrid", slots = numSlots, columns = slotWidth, containerSlot = 1 }
  } },
  { { size = 16 },
    { type = "label", text = "(" .. numSlots .. " slots)" },
    "spacer",
    { id = "takeAll", type = "button", caption = "Take All", size = 40 }
  },
}

local icfg = root.itemConfig { name = world.entityTypeName(src), parameters = { }, count = 1 }

cfg.icon = util.absolutePath(icfg.directory, world.getObjectParameter(src, "inventoryIcon"))
cfg.title = world.getObjectParameter(src, "shortdescription")

local esUIColors = {
  ["?hueshift=-110?saturation=40?brightness=10"] = "ff4942", -- red
  ["?hueshift=-80?saturation=80?brightness=35"] = "ffb42f", -- orange
  ["?hueshift=-55?saturation=76?brightness=40"] = "ffef1e", -- yellow
  --[""] == "4fe646", -- green
  ["?hueshift=45?saturation=50?brightness=10"] = "3de2a2", -- mint
  ["?hueshift=65?saturation=65?brightness=20"] = "00dce9", -- cyan
  ["?hueshift=88?saturation=50?brightness=14"] = "2660ff", -- blue
  ["?hueshift=100?saturation=50?brightness=0"] = "183da3", -- darkblue
  ["?hueshift=155?saturation=20?brightness=15"] = "a077ff", -- purple
  ["?hueshift=180?saturation=40?brightness=15"] = "ffa2bb", -- pink
}

local guiColor = world.getObjectParameter(src, "guiColor")
cfg.accentColor = esUIColors[guiColor or false]
