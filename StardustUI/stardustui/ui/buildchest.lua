-- Automatic chest interface

cfg = {
  style = "window",
  scripts = { "chest.lua" },
}

local src = pane.sourceEntity()
local numSlots = world.containerSize(src)

local widths = { 4, 5, 6, 7, 8, 10 }
local wdef = {
  [1] = 1,
  [2] = 2,
  [3] = 3,
  [4] = 2,
  [5] = 3,
  [6] = 3,
  [7] = 4,
  [8] = 4,
  [9] = 3,
  [10] = 5,
  [11] = 4,
  [12] = 4,
  
  [19] = 4,
}
local function ssp(sw)
  local sh = math.ceil(numSlots / sw)
  local mn = math.min(sw, sh)
  local mx = math.max(sw, sh)
  local rem = numSlots % sw
  
  local p = mn/mx
  if rem == math.ceil(sw/2) then
  else p = p - (rem / sw) * 2 end
  if sw > sh then p = p - 0.25 end
  
  return p
end

local slotWidth
if numSlots >= 100 then slotWidth = 10
elseif wdef[numSlots] then slotWidth = wdef[numSlots]
else
  local p = -1000
  for _, sw in pairs(widths) do
    local pp = ssp(sw)
    if pp > p then
      slotWidth = sw
      p = pp
    end
  end
end
local slotHeight = math.ceil(numSlots / slotWidth)

local hasES
local esScripts = {
  ["/scripts/enhancedstorage.lua"] = true,
}
for _,s in pairs(world.getObjectParameter(src, "scripts") or { }) do
  if esScripts[s] then hasES = esScripts[s] break end
end

local barHeight = 9--16

cfg.size = {
  util.clamp(slotWidth, hasES and 4.25 or 4, 10) * 20 - 2,
  util.clamp(slotHeight, 3, 10.5) * 20 - 2 + barHeight+2,
}
local overflow = slotHeight > 10

-- only spawn the scroll area when overflow happens
local grid = { id = "itemGrid", type = "itemGrid", expandMode = {2, 2}, slots = numSlots, columns = math.min(slotWidth, numSlots), containerSlot = 1, directCache = true }
if overflow then
  cfg.size[1] = cfg.size[1] + 4+2 -- compensate for the added width of the panel, plus room for count
  grid = { type = "panel", style = "concave", mode = "vertical", children = { -- and wrap in scrolling
    { type = "scrollArea", expandMode = {2, 2}, children = { grid, 0 } },
  } }
else
  grid = { type = "layout", mode = "horizontal", scissoring = false, expandMode = {2, 2}, children = { "spacer", grid, "spacer" } }
end

cfg.children = { { scissoring = false }, -- allow count to slightly overlap window border
  grid,
  { { size = barHeight },
    -1, -- tiny bit of space away from edge
    { -- bar and label is an extension of the Take All button
      { id = "slotsBar", mode = "h", expandMode = {2, 0}, size = barHeight },
      { id = "slotsLabel", type = "label", text = numSlots .. " slots", expand = true },
      { id = "takeAll", type = "iconButton", image = "takeall.png", toolTip = "Take All" },
    },
    -3, { id = "quickStack", type = "iconButton", image = "quickstack.png", toolTip = "Quick Stack" },
    -3, { id = "sort", type = "iconButton", image = "sort.png", toolTip = "Sort" },
    hasES and -3 or { },
    { id = "esOptions", type = "iconButton", image = "minimenu.png", toolTip = "Container Options", visible = not not hasES },
    -1, -- same spacer on the end too
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
