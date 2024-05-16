-- Stardust UI inventory replacement

-- /run player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = "stardustui:inventory" })

require "/scripts/util.lua"
require "/lib/stardust/itemutil.lua"

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

--[[
local i
for i = 1, 5 do
  local tab = bagTabs:newTab { id = "" .. i }
  tab.tabWidget.explicitSize = { bagTabs.tabWidth, 20 }
end-- ]]

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

local numActionBarSlots = root.assetJson("/player.config").inventory.customBarIndexes
function swapActionBarLinks(a, b, uni)
  local cmt = { }
  local hands = {"primary", "alt"}
  local function cmp(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return a == b end
    return a[1] == b[1] and a[2] == b[2]
  end
  
  local i
  for i = 1, numActionBarSlots do
    for _, hand in pairs(hands) do
      local lnk = player.actionBarSlotLink(i, hand)
      if cmp(lnk, a) then
        table.insert(cmt, function() player.setActionBarSlotLink(i, hand, b) end)
      elseif (not uni) and cmp(lnk, b) then
        table.insert(cmt, function() player.setActionBarSlotLink(i, hand, a) end)
      end
    end
  end
  
  local function cc()
    for _,f in pairs(cmt) do f() end
  end
  cc()
  return cc
end

-- and define item grid behavior
itemGrid.onCaptureMouseMove = mg.widgetTypes.button.onCaptureMouseMove
function itemGrid:onSlotMouseEvent(btn, down) -- remember, self is the *slot*, not the grid
  if down then self:captureMouse(btn) return true
  elseif btn == self:mouseCaptureButton() then
    self:releaseMouse()
  else return end
  
  local bag = bagTabs.currentTab._bag
  if not bag then return end
  local sd = {bag.name, self.index - 1}
  local swd = "swap"
  local itm = player.item(sd)
  
  local pta = root.getConfigurationPath("inventory.pickupToActionBar")
  
  local shift = mg.checkShift()
  if shift and btn == 0 then -- shift+lclick into an open container
    if not ipc.openContainerId or not world.containerSize(ipc.openContainerId) then return end
    if not itm then return end -- no item
    local lo = world.containerItemsFitWhere(ipc.openContainerId, itm).leftover
    local res = world.containerAddItems(ipc.openContainerId, itm)
    res.count = lo
    player.setItem(sd, res)
    self:setItem(res) -- update immediately
  else -- normal click
    local stm = player.swapSlotItem()
    if not itm and not stm then return end -- nothing to do
    --if itm and stm and not root.itemDescriptorsMatch(itm, stm) then return end -- 
    if stm and not player.itemAllowedInBag(bag.name, stm) then return end -- carrying forbidden item; game will reject placement
    
    root.setConfigurationPath("inventory.pickupToActionBar", false)
    -- BE CAREFUL ABOUT RETURNING HERE ^^^
    if btn == 0 then -- left click
      if not mg.itemsCanStack(itm, stm) then -- heterogenous: plonk in/swap
        local commit = swapActionBarLinks(sd, swd)
        player.setItem(sd, stm)
        player.setSwapSlotItem(itm)
        commit()
      else -- homogenous: attempt to stack into
        -- we know both items exist and are the same
        local maxStack = mg.itemMaxStack(itm)
        local xf = math.min(maxStack - itm.count, stm.count) -- max transfer
        if xf > 0 then -- we want to transfer more than zero, do the thing
          swapActionBarLinks(swd, sd, true) -- deposit links from swap slot into inventory
          itm.count = itm.count + xf
          stm.count = stm.count - xf
          player.setItem(sd, itm)
          player.setSwapSlotItem(stm)
        end
      end
    elseif btn == 2 and (not stm or mg.itemsCanStack(itm, stm)) then
      -- homogenous or none only: attempt to pull one/half into swap slot
      if not stm then -- zero stack
        stm = util.mergeTable({ }, itm)
        stm.count = 0
      end
      local maxStack = mg.itemMaxStack(itm)
      local xf = math.min(maxStack - stm.count, itm.count) -- max transfer
      if shift then
        xf = math.min(xf, math.max(math.floor(itm.count/2), 1))
      else
        xf = math.min(xf, 1)
      end
      if xf > 0 then -- we want to transfer more than zero, do the thing
        itm.count = itm.count - xf
        stm.count = stm.count + xf
        if itm.count == 0 then -- last of it
          swapActionBarLinks(sd, swd, true) -- yoink bar link
        end
        player.setItem(sd, itm)
        player.setSwapSlotItem(stm)
      end
    end
  end
  root.setConfigurationPath("inventory.pickupToActionBar", pta)
  return true
end

local equipSlots = { }
do -- set up equipment slots
  local mouseEv = function(self, btn, down)
    if down then self:captureMouse(btn) return
    elseif btn == self:mouseCaptureButton() then
      self:releaseMouse()
    else return end
    
    if btn == 1 or btn > 2 then return end -- only left/right
    
    local itm = player.equippedItem(self._slotName)
    local stm = player.swapSlotItem()
    
    if false then
      -- TODO augments
    else
      if not stm or root.itemType(stm.name) == self._accepts then -- fits
        player.setEquippedItem(self._slotName, stm)
        player.setSwapSlotItem(itm)
      end
    end
  end
  
  local sn = {"back", "head", "chest", "legs"}
  local sv = {"", "Cosmetic"}
  -- (str:gsub("^%l", string.upper))
  for _, sb in pairs(sn) do
    for _, v in pairs(sv) do
      local s = sb .. v
      local S = s:gsub("^%l", string.upper) -- capitalize
      local slot = _ENV["slot" .. S]
      slot._slotName = s
      slot._accepts = sb .. "armor"
      equipSlots[s] = slot
      slot.onMouseButtonEvent = mouseEv
    end
  end
end

function slotTrash:onMouseButtonEvent(btn, down)
  if down then self:captureMouse(btn) return
  elseif btn == self:mouseCaptureButton() then
    self:releaseMouse()
  else return end
  
  if btn == 1 or btn > 2 then return end -- only left/right
  
  if btn == 0 and mg.checkShift() then -- shift click back into inventory
    player.giveItem(self:item())
    self:setItem(nil)
  else -- normal click
    local stm = player.swapSlotItem()
    if not stm then -- no item in cursor, pull out
      player.setSwapSlotItem(self:item())
      self:setItem(nil)
    else -- trash item in cursor
      self:setItem(stm)
      player.setSwapSlotItem(nil)
    end
  end
end

-- -- -- -- --

local pid = player.id()
function drawPortrait()
  local drw = world.entityPortrait(pid, "Full")
  if drw then
    local scale = 1.5
    local off = {-10, 0}
    local c = portraitCanvas:bind()
    c:clear()
    
    -- position (vec2), transformation (table)
    -- image (string), color (table), fullbright (bool, irrelevant)
    for k,v in pairs(drw) do
      -- TODO?? figure out wtf transformation means here
      c:drawImage(v.image, vec2.add(off, vec2.mul(v.position, scale)), scale, v.color, false)
    end
  end
end

local function numStr(n, percent) -- friendly string representation of number
  if percent then n = math.floor(0.5 + n * 10000) / 100 end
  n = math.floor(n*100+0.5)/100 -- limit to two decimal points
  local fn = math.floor(n)
  if math.abs(fn - n) < 0.05 then n = fn end
  return tostring(n) .. (percent and "%" or "")
end

function updateStats()
  -- combat stats
  statHealth:setText(numStr(status.stat("maxHealth")))
  statEnergy:setText(numStr(status.stat("maxEnergy")))
  statArmor:setText(numStr(status.stat("protection")))
  statAttack:setText(numStr(status.stat("powerMultiplier"), true))
  
  -- currencies
  lblPixels:setText(player.currency("money"))
  local essence = player.currency("essence")
  rEssence:setVisible(essence > 0)
  if rEssence.visible then
    lblEssence:setText(essence)
  end
end updateStats()

function updateEquipment()
  for s, slot in pairs(equipSlots) do
    slot:setItem(player.equippedItem(s))
  end
end

function updateItems()
  local bag = bagTabs.currentTab._bag
  if not bag then return end
  
  local i
  for i = 1, bag.size do
    itemGrid:setItem(i, player.item{bag.name, i-1})
  end
end

local vpane = interface.bindRegisteredPane "Inventory"
function update()
  drawPortrait()
  updateStats()
  
  updateEquipment()
  updateItems()
  
  if not vpane.isDisplayed() then pane.dismiss() end
end

function uninit()
  vpane.dismiss()
end
