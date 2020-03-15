-- transmatter terminal, metaGUI edition

require "/lib/stardust/itemutil.lua"
require "/lib/stardust/sync.lua"

local termItems = { }
local termSyncUid

-- force scroll bars to show up on opening
metagui.startEvent(function()
	for i = 1,60*1.5 do
		scrollArea:scrollBy {1, 0}
		coroutine.yield()
	end
end)

local function waitFor(p) -- wait for promise
  while not p:finished() do coroutine.yield() end
  return p
end

local refreshNow = false
local function refresh() refreshNow = true end
metagui.startEvent(function()
  while true do
    refreshNow = false
    local p = waitFor(world.sendEntityMessage(pane.sourceEntity(), "updateItems"))
    if p:succeeded() then 
      refreshNow = false
      local items, uid = p:result()
      termItems = items
			if true or uid ~= termSyncUid then
				termSyncUid = uid
				refreshDisplay()
			end
    end
    for i = 1, 30 do
      if refreshNow then break end
      coroutine.yield()
    end
  end
end)

function refreshDisplay()
  --prevShownItems = shownItems
  local shownItems = {}
  local i = 1
  local search = "" -- TEMP
  if search == "" then
    for k,v in pairs(termItems) do
      shownItems[i] = v
      i = i + 1
    end
  elseif search:sub(1, 2) == "/ " then
    local filter = search:sub(3)
    for k,v in pairs(termItems) do
      if itemutil.matchFilter(filter, v) then
        shownItems[i] = v
        i = i + 1
      end
    end
  else
    for k,v in pairs(termItems) do
      if string.find(string.lower(v.parameters.shortdescription or root.itemConfig(v).config.shortdescription), search) then
        shownItems[i] = v
        i = i + 1
      end
    end
  end
  
  table.sort(shownItems, itemSortByCount)
	
	local ns = #shownItems
	local ens = math.max(1, math.ceil(ns/grid.columns) * grid.columns)
	grid:setNumSlots(ens)
	for k, v in pairs(shownItems) do grid:slot(k):setItem(v) end
	for i = ns+1, ens do grid:slot(i):setItem() end -- clear empties
end

function itemSortByCount(i1, i2)
  local c1, c2 = itemutil.getCachedConfig(i1), itemutil.getCachedConfig(i2)
  if i1.count ~= i2.count then return i1.count > i2.count end -- > because most-first
  local n1, n2 = i1.parameters.shortdescription or c1.config.shortdescription, i2.parameters.shortdescription or c2.config.shortdescription
	return n1 < n2; 
end

function request(reqItem, count)
  if not reqItem.name then return nil end -- no item selected!
  sync.poll("request", nil, {
    name = reqItem.name,
    count = math.min(count or 999999999, reqItem.parameters.maxStack or itemutil.getCachedConfig(reqItem).config.maxStack or 1000),
    parameters = reqItem.parameters
  }, player.id())
	refresh()
end

grid.onCaptureMouseMove = metagui.widgetTypes.button.onCaptureMouseMove
function grid:onSlotMouseEvent(btn, down)
	if down and not self:hasMouse() then
		scrollArea.velocity = {0, 0} -- force stop
		self:captureMouse(btn)
	elseif not down then
		if btn == self:mouseCaptureButton() then
			self:releaseMouse()
			
			if btn ~= 1 then
				local b = nil;
				local cur = itemutil.normalize(player.swapSlotItem() or {})
				local reqItem = self:item()
				local maxStack = itemutil.property(reqItem, "maxStack") or 1000
				if cur.count > 0 and (not reqItem or not itemutil.canStack(reqItem, cur)) then -- deposit
					player.setSwapSlotItem(world.containerAddItems(pane.sourceEntity(), cur)[1])
					return true
				end
				if not reqItem then return true end -- no trying to request blanks
				if itemutil.canStack(reqItem, cur) and cur.count < maxStack then b = maxStack - cur.count end
				if btn == 2 then b = 1 end
				request(reqItem, b)
			end
		end
	end
	return true
end
