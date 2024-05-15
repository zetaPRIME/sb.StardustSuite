-- Stardust UI inventory replacement

-- /run player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = "stardustui:inventory" })

local mg = metagui

--local itemBags
itemBagsById = { }
local maxBagSize = 0
do -- set up item bag data
  itemBags = root.assetJson("/player.config").inventory.itemBags -- bag config
  local vi = root.assetJson("/interface/windowconfig/playerinventory.config") -- vanilla inventory
  
  for k, v in pairs(vi.bagConfig) do
    local bag = itemBags[k]
    bag.name = k
    bag.id = v.order
    itemBagsById[v.order] = bag
    bag.icon = vi.paneLayout.gridModeSelector.buttons[bag.id].baseImage
    maxBagSize = math.max(maxBagSize, bag.size)
  end
  
end

for k, bag in ipairs(itemBagsById) do -- set up tabs
  local tab = bagTabs:newTab { id = bag.name, icon = bag.icon, title = "" }
  tab.titleWidget:setVisible(false)
  tab.tabWidget.explicitSize = { bagTabs.tabWidth, 20 }
  tab.iconWidget.explicitSize = { bagTabs.tabWidth - 2, 20 }
  tab._bag = bag
end

bagTabs.stack:addChild {
  type = "scrollArea", children = {
    { id = "itemGrid", type = "itemGrid", slots = maxBagSize }
  }
}

-- -- -- -- --

function init()
  --portraitContainer:addChild { type = "portrait" }
  --portraitCanvas = mg.createWidget { type = "canvas" }--portraitContainer:addChild { type = "canvas" }
end

local pid = player.id()
function drawPortrait()
  local drw = world.entityPortrait(pid, "Full")
  if drw then
    local c = portraitCanvas:bind()
    c:clear()
    --c:drawRect({0, 0, 200, 200}, {0, 0, 0, 63})
    
    -- position (vec2), transformation (table)
    -- image (string), color (table), fullbright (bool, irrelevant)
    for k,v in pairs(drw) do
      -- TODO?? figure out wtf transformation means here
      c:drawImage(v.image, v.position, 1.0, v.color, false)
    end
  end
end

function updateItems()
  local bag = bagTabs.currentTab._bag
  sb.logInfo("bag is: " .. bag.name)
  local ac = player.actionBarSlotLink(1, "primary")
  for k,v in pairs(ac) do
    sb.logInfo(k .. ": " .. v)
  end
  
  local i
  for i = 1, bag.size do
    itemGrid:setItem(i, player.item{bag.name, i-1})
  end
end

function update()
  drawPortrait()
  
  updateItems()
end
