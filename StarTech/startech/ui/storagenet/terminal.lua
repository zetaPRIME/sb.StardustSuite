-- transmatter terminal, metaGUI edition

require "/lib/stardust/itemutil.lua"

local termItems = { }
local termSyncUid

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
	
  grid:setNumSlots(i-1)
	for k, v in pairs(shownItems) do
		grid:slot(k):setItem(v)
	end
end

function itemSortByCount(i1, i2)
  local c1, c2 = itemutil.getCachedConfig(i1), itemutil.getCachedConfig(i2)
  if i1.count ~= i2.count then return i1.count > i2.count end -- > because most-first
  local n1, n2 = i1.parameters.shortdescription or c1.config.shortdescription, i2.parameters.shortdescription or c2.config.shortdescription
	return n1 < n2; 
end
