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
