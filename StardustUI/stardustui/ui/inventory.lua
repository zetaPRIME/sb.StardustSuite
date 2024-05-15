-- Stardust UI inventory replacement

-- /run player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = "stardustui:inventory" })

local mg = metagui
local ipc = getmetatable''["stardustui:"]
if not ipc then ipc = { } getmetatable''["stardustui:"] = ipc end

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
  id = "itemGridContainer", type = "scrollArea", children = {
    { id = "itemGrid", type = "itemGrid", slots = itemBagsById[1].size }
  }
}

-- on bag switch
itemGrid:subscribeEvent("tabChanged", function(self, tab)
  local bag = tab._bag
  itemGridContainer:setVisible(not not bag)
  if bag then
    self:setNumSlots(bag.size)
  end
end)

function itemGrid:onSlotMouseEvent(btn, down) -- remember, self is the *slot*, not the grid
  if down then self:captureMouse(btn) return
  elseif btn == self:mouseCaptureButton() then
    self:releaseMouse()
  else return end
  
  local bag = bagTabs.currentTab._bag
  if not bag then return end
  local sd = {bag.name, self.index - 1}
  
  local shift = mg.checkShift()
  if shift then
    if btn ~= 0 then return end -- only left button
    -- only into an open container
    if not ipc.openContainerId or not world.containerSize(ipc.openContainerId) then return end
    local itm = player.item(sd)
    if not itm then return end -- no item
    local lo = world.containerItemsFitWhere(ipc.openContainerId, itm).leftover
    local res = world.containerAddItems(ipc.openContainerId, itm)
    res.count = lo
    player.setItem(sd, res)
    self:setItem(res) -- update immediately
  end
end

-- -- -- -- --

local pid = player.id()
function drawPortrait()
  local drw = world.entityPortrait(pid, "Full")
  if drw then
    local c = portraitCanvas:bind()
    c:clear()
    
    -- position (vec2), transformation (table)
    -- image (string), color (table), fullbright (bool, irrelevant)
    for k,v in pairs(drw) do
      -- TODO?? figure out wtf transformation means here
      c:drawImage(v.image, v.position, 1.0, v.color, false)
    end
  end
end

function updateStats()
  
end

function updateEquipment()
  
end

function updateItems()
  local bag = bagTabs.currentTab._bag
  if not bag then return end
  
  local i
  for i = 1, bag.size do
    itemGrid:setItem(i, player.item{bag.name, i-1})
  end
end

function update()
  drawPortrait()
  updateStats()
  
  updateEquipment()
  updateItems()
end
