--
require "/lib/stardust/network.lua"
require "/lib/stardust/playerext.lua"

storagenet = { }

-- each discrete type of item takes up 24 bytes of capacity; each count of item takes one bit
local typeBits = 24 * 8

--------------------------
-- Storage Provider API --
--------------------------

-- Variable notes --
-- sp.slot - 1-8; item slot of the drive it's attached to
-- sp.item - full itemdescriptor of the drive
--+sp.item.parameters.syncId - generated unique ID, refreshed every commit
--+sp.item.parameters.contents - exactly what it sounds like
--+sp.item.parameters.filter / priority
--+sp.item.parameters.bitsUsed

-- sp.driveParameters.capacity - bits used

local driveProviders = { }

local provider = { }

function provider:onConnect(slot)
  self.slot = slot
  self.data = storage.drives[slot].parameters.contents
  self:updateItemCounts(self.data)
  driveProviders[slot] = self
end

function provider:onDisconnect(slot)
  driveProviders[self.slot] = nil
end

function storagenet:onConnect()
  storage.drives = storage.drives or { }
  for slot in pairs(storage.drives) do storagenet:registerStorage(provider, slot) end
end
