--
require "/lib/stardust/network.lua"
require "/lib/stardust/playerext.lua"

storagenet = { }

local lights = { }

-- each discrete type of item takes up 24 bytes of capacity; each count of item takes one bit
local typeBits = 24 * 8

--------------------------
-- Storage Provider API --
--------------------------

-- Variable notes --
-- sp.slot - 1-8; item slot of the drive it's attached to
-- sp.item - full itemdescriptor of the drive
--+sp.item.parameters.syncId - generated unique ID, refreshed every commit - is this actually necessary?
--+sp.item.parameters.contents - exactly what it sounds like
--+sp.item.parameters.filter / priority
--+sp.item.parameters.bitsUsed

-- sp.driveParameters.capacity - bits used

local driveProviders = { }

local provider = { }

function provider:onConnect(slot)
  self.slot = slot
  self.item = storage.drives[slot]
  if not self.item.parameters.contents then self.item.parameters.contents = { } end
  self:updateItemCounts(self.item.parameters.contents)
  driveProviders[slot] = self
  lights[slot] = true
  updateLights()
end

function provider:onDisconnect()
  driveProviders[self.slot] = nil
  lights[self.slot] = nil
  updateLights()
end

function provider:tryTakeItem(req, test)
  if req.count <= 0 then return 0 end -- not actually requesting anything
  local itm, idx
  for i, ii in pairs(self.item.parameters.contents) do
    if root.itemDescriptorsMatch(req, ii, true) then itm, idx = ii, i break end
  end
  if not itm then return 0 end -- not found
  local rc = math.min(itm.count, req.count)
  if not test then
    itm.count = itm.count - rc
    if itm.count <= 0 then
      table.remove(self.item.parameters.contents, idx)
    end
    self:updateItemCounts(itm)
  end
  return rc
end

function provider:tryPutItem(req, test)
  if req.count <= 0 then return 0 end -- not actually inserting anything
  local itm, idx
  for i, ii in pairs(self.item.parameters.contents) do -- find existing stack
    if root.itemDescriptorsMatch(req, ii, true) then itm, idx = ii, i break end
  end
  local count = req.count
  if itm then
    itm.count = itm.count + count
  else
    itm = { name = req.name, parameters = req.parameters, count = count }
    table.insert(self.item.parameters.contents, itm)
  end
  self:updateItemCounts(itm)
    
  return count
end

function storagenet:onConnect()
  storage.drives = storage.drives or { }
  for slot in pairs(storage.drives) do storagenet:registerStorage(provider, slot) end
end

function updateLights()
  object.setAnimationParameter("lights", lights)
end

-- -- --

local svc = { } -- message handlers

function svc.getDisplayItems() -- get drives for display; no sending hueg contents table
  local i = { false, false, false, false, false, false, false, false }
  for slot, itm in pairs(storage.drives) do
    i[slot] = { name = itm.name, count = 1, parameters = { } }
    for k, v in pairs(itm.parameters) do
      if k ~= "contents" then i[slot].parameters[k] = v end
    end
  end
  return i
end

function svc.swapDrive(pid, slot, item)
  -- verify that this is actually a drive
  if item and not root.itemConfig(item).config.driveParameters then
    playerext.setPlayer(pid).giveItemToCursor(item)
    return nil
  end
  
  local sp = driveProviders[slot]
  if sp then sp:disconnect() end -- kill provider
  local old = storage.drives[slot] -- hold old item for a sec
  storage.drives[slot] = item
  if item and storagenet.connected then
    storagenet:registerStorage(provider, slot)
  end
  playerext.setPlayer(pid).giveItemToCursor(old)
end

function svc.getInfo(slot)
  local sp = driveProviders[slot]
  if not sp then return nil end
  return { slot = slot, filter = sp.item.parameters.filter or "", priority = sp.item.parameters.priority or 0 }
end

function svc.setInfo(slot, filter, priority)
  local sp = driveProviders[slot]
  if not sp then return nil end
  sp.item.parameters.priority = priority
  if filter == "" then filter = nil end
  sp.item.parameters.filter = filter
  sp:commit()
end

-- -- --

function init()
  updateLights()
  for k, f in pairs(svc) do message.setHandler("drivebay:"..k, function(_, _, ...) return f(...) end) end
end

function die()
  local pos = world.entityPosition(entity.id())
  
  while true do -- disconnect and drop all drives
    local _, sp = pairs(driveProviders)(driveProviders)
    if not sp then break end
    sp:disconnect()
    world.spawnItem(sp.item, pos)
  end
end
