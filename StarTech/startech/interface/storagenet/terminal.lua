-- TODO - Terminal edition
-- DONE add description(? category?), distinct request buttons (1, 10, 100, 1000 should be fine I guess)
-- DONE doubleclick to grab a stack
-- DONE of course, finish the visual redesign
-- rarity display on selection?
-- maybe more sorting modes
-- variable color for on-icon count (maybe red being in the millions? *shrug*)
-- ...search additions? @category etc.

-- add entry background with selection indicator!!

require "/scripts/vec2.lua"

require "/lib/stardust/sync.lua"
require "/lib/stardust/itemutil.lua"
require "/scripts/StarTech/tooltip.lua"

gridSize = 24
gridSpace = 25
gridWidth = 8 -- 8 max

if false then -- testing probe
  setmetatable(_ENV, { __index = function(t,k)
    sb.logInfo("missing field "..k.." accessed")
    local f = function(...)
      sb.logInfo("called")
    end
    return nil -- f
  end })
end

function init()
  items = {}
  itemUpdateId = "NaN"
  shownItems = {}
  prevShownItems = {}
  selectedItem = {}
  selectedId = -1
  --itemButtons = {}
  listId = {}
  slotId = {}
  widget.clearListItems("grid.list")
  search = ""
  searchTime = 0
  updateTime = 0
  heartbeatTime = 0
  
  pid = pane.playerEntityId()
  sync.msg("playerOpen", pid)
  
  --if status then sb.logInfo("status exists in panes!") end
end

function update()
  --
  
  updateTime = updateTime - 1
  if updateTime <= 0 then updateItemList() end
  searchTime = searchTime - 1
  if searchTime == 0 then refreshDisplay() end
  
  heartbeatTime = heartbeatTime - 1
  if heartbeatTime <= 0 then
    sync.msg("playerHeartbeat", pid)
    heartbeatTime = math.floor(60 * 0.1)
  end
  
  sync.runQueue()
end

function uninist()
  dismissed()
end
function dismissed() --uninit()
  sync.msg("playerClose", pid)
end

function btnExpandInfo()
  setExpandedInfo()
  -- temp: test playerext
  --world.sendEntityMessage(pane.playerEntityId(), "playerext:openInterface", "/interface/cockpit/cockpit.config")
end
infoExpanded = false
function setExpandedInfo(setting)
  if setting == nil then setting = not infoExpanded end
  infoExpanded = setting
  
  local btnImg = "/interface/tech/storagenet/buttons/expandinfo.png"
  
  if setting then
    widget.setSize("selItem_description", { 300, 132 })
    widget.setPosition("expandedinfocover", { 0, 0 })
    widget.setPosition("selItem_label", { 35, 142 })
    
    btnImg = btnImg .. "?flipy"
  else
    widget.setSize("selItem_description", { 300, 30 })
    widget.setPosition("expandedinfocover", { 5730, 0 })
    widget.setPosition("selItem_label", { 35, 39 })
  end
  
  widget.setButtonImages("expandinfo", {
    base = btnImg .. "?replace;ffffff=bfbfbf",
    hover = btnImg
  })
end

function selectItem(i, updating)
  setExpandedInfo(false)
  if i < 0 then -- -1 == blank
    selectedItem = {}
    selectedId = -1 -- hmm. I wonder..
    widget.clearListItems("selItem_icon")
  
    widget.setText("selItem_label", "")
    widget.setText("selItem_description.text", "")
    return nil
  end
  if not updating and selectedId >= 0 then
    if listId[selectedId] then widget.setVisible(listId[selectedId] .. ".selection", false) end -- visibly deselect
  end
  selectedItem = shownItems[i]
  if not updating then 
    if listId[selectedId] then widget.setVisible(listId[selectedId] .. ".selection", false) end -- visibly deselect...
    if listId[i] then widget.setVisible(listId[i] .. ".selection", true) end -- and highlight the new selection
  end 
  selectedId = i
  applyIcon(selectedItem, "selItem_icon")
  
  local conf = getConf(selectedItem)
  
  widget.setText("selItem_label", table.concat({ selectedItem.parameters.shortdescription or conf.config.shortdescription, " ^#7fffff;(x", selectedItem.count, ")" }))
  --if not updating then widget.setText("selItem_description.text", "") end -- try to reset scroll height
  
  local addInfo = ""
  if conf.config.itemTags and conf.config.itemTags[1] == "weapon" then
    addInfo = tooltip.weaponInfo(selectedItem, nil, "\n")
  end
  
  widget.setText("selItem_description.text", table.concat({
    selectedItem.parameters.description or conf.config.description or "",
    addInfo
  }))
  --sb.logInfo(sb.printJson(root.itemConfig(selectedItem)))
end

function updateItemList()
  sync.poll("updateItems", onRecvItemList, itemUpdateId)
  updateTime = math.floor(60*0.5)
end

local requestBtn = {
  req1 = 1,
  req10 = 10,
  req100 = 100,
  req1000 = 1000
}
function request(btn)
  if not selectedItem.name then return nil end -- no item selected!
  sync.poll("request", updateItemList(), {
    name = selectedItem.name,
    count = math.min((type(btn) == "number" and btn) or requestBtn[btn] or 1000, selectedItem.parameters.maxStack or getConf(selectedItem).config.maxStack or 1000),
    parameters = selectedItem.parameters
  }, pane.playerEntityId())
end

function onRecvItemList(rpc)
  if not rpc:succeeded() then return nil end
  local rItems, rUid = rpc:result()
  if not rItems then return nil end
  items = rItems
  itemUpdateId = rUid -- TODO: FIX THIS
  refreshDisplay()
end

function refresh()
  -- doop de doo
  local lpos = widget.getPosition("grid.list")
  widget.setPosition("grid.list", {lpos[1] + 2, lpos[2]})
end

function searchBox()
  search = string.lower(widget.getText("searchBox"))
  --refreshDisplay()
  searchTime = 5 -- avoid clobbering with lag
end
function searchBoxEsc()
  widget.blur("searchBox")
end
function searchBoxEnter()
  widget.blur("searchBox")
end

function refreshDisplay()
  prevShownItems = shownItems
  shownItems = {}
  local i = 1
  if search == "" then
    for k,v in pairs(items) do
      shownItems[i] = v
      i = i + 1
    end
  elseif search:sub(1, 2) == "/ " then
    local filter = search:sub(3)
    for k,v in pairs(items) do
      if itemutil.matchFilter(filter, v) then
        shownItems[i] = v
        i = i + 1
      end
    end
  else
    for k,v in pairs(items) do
      if string.find(string.lower(v.parameters.shortdescription or root.itemConfig(v).config.shortdescription), search) then
        shownItems[i] = v
        i = i + 1
      end
    end
  end
  
  table.sort(shownItems, itemSortByCount)
  buildList()
end

function resizeList(count)
  local num = #listId
  if count < num then -- remove
    for i = num, count + 1, -1 do
      listId[i] = nil
      slotId[i] = nil
      widget.removeListItem("grid.list", i-1)
    end
  elseif count > num then -- add
    for i = num + 1, count do
      listId[i] = "grid.list." .. widget.addListItem("grid.list")
      
      local wcount = listId[i] .. ".count"
      widget.setPosition(wcount, {gridSpace - 2, 0})
      
      local wslot = listId[i] .. ".slotcontainer"
      local ix = i
      widget.registerMemberCallback(wslot, "left", function(name, shift) onSlotClick(ix, 0, shift) end)
      widget.registerMemberCallback(wslot, "right", function(name, shift) onSlotClick(ix, 1, shift) end)
      
      slotId[i] = table.concat({ wslot, ".", widget.addListItem(wslot), ".slot" })
    end
  end
end

function buildList()
  local count = #shownItems
  
  local foundSel = false
  
  resizeList(count)
  for i = 1, count do
    widget.setText(listId[i] .. ".count", prettyCount(shownItems[i].count or 1))
    if not prevShownItems[i] or not itemutil.canStack(shownItems[i], prevShownItems[i]) then
      -- only set item if it should have changed, so as to avoid visible lag with every refresh
      widget.setItemSlotItem(slotId[i], { name = shownItems[i].name, count = 1, parameters = shownItems[i].parameters })
    end
    if listId[i] then widget.setVisible(listId[i] .. ".selection", false) end -- visibly deselect everything, to be reselected after
    if selectedItem.name and itemutil.canStack(selectedItem, shownItems[i]) then selectedItem = shownItems[i] foundSel = i end -- preserve selection
  end
  
  if not foundSel then
    selectItem(-1) -- clear selection data
  else
    selectItem(foundSel) -- rehighlight selection and update tooltip
  end
  widget.setPosition("grid.nudge", {0, (math.ceil((count-1) / gridWidth) * -gridSpace) - 2}); -- TODO: de-hardcode this some
end

function onSlotClick(id, button, shift)
  --sb.logInfo("hello! slot " .. id .. " button " .. button)
  if shift then sb.logInfo("shift??") end
  if selectedId ~= id then
    selectItem(id)
    if button == 1 then return nil end -- select only if rightclicked when not selected
  end
  local b = nil;
  local cur = itemutil.normalize(player.swapSlotItem() or {})
  local maxStack = itemutil.property(selectedItem, "maxStack") or 1000
  if itemutil.canStack(selectedItem, cur) and cur.count < maxStack then b = maxStack - cur.count end
  if button == 1 then b = 1 end
  request(b)
end

function prettyCount(num)
  if num < 1 then return "craft"
  elseif num > 999999999 then return math.floor(num / 1000000000) .. "B"
  elseif num > 999999 then return math.floor(num / 1000000) .. "M"
  elseif num > 9999 then return math.floor(num / 1000) .. "K"
  end
  return "" .. num
  
end

function applyIcon(item, wid, doFrame)
  if not wid then return nil end -- apparently this can happen
  widget.clearListItems(wid) -- because reinit
  
  local conf = getConf(item) -- root.itemConfig(item)
  
  if doFrame then
    local xicon = "/interface/tech/storagenet/itemSlot.png"
    if item == selectedItem then xicon = "/interface/tech/storagenet/itemSlot.selected.png" end
    local layer = table.concat({ wid, ".", widget.addListItem(wid), ".icon" })
    widget.setImage(layer, xicon)
    
    layer = table.concat({ wid, ".", widget.addListItem(wid), ".icon" })
    widget.setImage(layer, table.concat({ "/interface/tech/storagenet/itemSlot.rarity.", (item.parameters.rarity or conf.config.rarity or "common"):lower(), ".png" }))
  end
  
  --if true then return nil end -- disable icon view for now
    
	local icon = item.parameters.inventoryIcon or conf.config.inventoryIcon or conf.config.codexIcon
  
  local addColor = ""
  local colorOpt = item.parameters.colorOptions or conf.config.colorOptions
  if colorOpt then
    local colordef = colorOpt[(item.parameters.colorIndex or 0)+1]
    if colordef and type(colordef) ~= "table" then colordef = {colordef} end -- tablify anything that's not a table
    if colordef then
      local cb, i = {"?replace"}, 2
      for k,v in pairs(colordef) do
        cb[i] = ";"
        cb[i+1] = k
        cb[i+2] = "="
        cb[i+3] = v
        i = i + 4
      end
      cb[i] = item.parameters.directives -- might as well bake this in here
      addColor = table.concat(cb)
    end
  end
  
  if icon ~= nil and type(icon) == "string" then
    icon = {{image = icon}}
  end
  if icon ~= nil and type(icon) == "table" then
    local scale = 1
    local bounds = { 1000, 1000, 0, 0 }
    -- precalc stuff
    for i,v in pairs(icon) do
      local xicon = absolutePath(conf.directory, v.image)
      local ipos = v.position or {0,0}
      ipos = { ipos[1] * 0.75, ipos[2] * 0.75 } -- super silly hack, but it seems to fix guns being in pieces so ???
      local ibounds = root.nonEmptyRegion(xicon) or {0,0,0,0}
      
      -- take offsets into account
      ibounds[1] = ibounds[1] + ipos[1]
      ibounds[2] = ibounds[2] + ipos[2]
      ibounds[3] = ibounds[3] + ipos[1]
      ibounds[4] = ibounds[4] + ipos[2]
      
      bounds[1] = math.min(bounds[1], ibounds[1])
      bounds[2] = math.min(bounds[2], ibounds[2])
      bounds[3] = math.max(bounds[3], ibounds[3])
      bounds[4] = math.max(bounds[4], ibounds[4])
    end
    
    scale = math.min(scale, (gridSize) / (bounds[3] - bounds[1]))
    scale = math.min(scale, (gridSize) / (bounds[4] - bounds[2]))
    
    local offset = {
      (gridSize / 2 - ((bounds[3] - bounds[1]) * scale) / 2 - bounds[1] * scale),
      (gridSize / 2 - ((bounds[4] - bounds[2]) * scale) / 2 - bounds[2] * scale)
    }
    
    for i,v in pairs(icon) do
      local xicon = absolutePath(conf.directory, v.image) .. addColor
      local layer = table.concat({ wid, ".", widget.addListItem(wid), ".icon" })
      widget.setImage(layer, xicon)
      widget.setImageScale(layer, scale)
      local ipos = v.position or {0,0}
      ipos = { ipos[1] * 0.75, ipos[2] * 0.75 } -- don't modify original
      ipos[1] = (offset[1] + (ipos[1] * scale))
      ipos[2] = (offset[2] + (ipos[2] * scale))
      widget.setPosition(layer, ipos)
    end
  end
end

function absolutePath(directory, path)
  if type(path) ~= "string" then
  	return false;
  end
  if string.sub(path, 1, 1) == "/" then
    return path
  else
    return directory..path
  end
end


function dump(o, ind)
  if not ind then ind = 2 end
  local pfx, epfx = "", ""
  for i=1,ind do pfx = pfx .. " " end
  for i=3,ind do epfx = epfx .. " " end
  if type(o) == 'table' then
    local s = '{\n'
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. pfx .. '['..k..'] = ' .. dump(v, ind+2) .. ',\n'
    end
    return s .. epfx .. '}'
  else
    return tostring(o)
  end
end

-- moved into itemutil :D
getConf = itemutil.getCachedConfig

function itemSortByCount(i1, i2)
  local c1, c2 = getConf(i1), getConf(i2) -- root.itemConfig(i1), root.itemConfig(i2)
  if i1.count ~= i2.count then return i1.count > i2.count end -- > because most-first
  local n1, n2 = i1.parameters.shortdescription or c1.config.shortdescription, i2.parameters.shortdescription or c2.config.shortdescription
	return n1 < n2; 
end
