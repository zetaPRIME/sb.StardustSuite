--
require "/lib/stardust/network.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/itemutil.lua"

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
  self.driveParameters = itemutil.getCachedConfig(self.item).config.driveParameters
  self.priority = self.item.parameters.priority
  self:updateFilter()
  self:updateItemCounts(self.item.parameters.contents)
  self.dirty = true
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
      if type(idx) ~= "number" then -- something screwy is happening, fix to array
        self.item.parameters.contents[idx] = nil
        self:reseatIndices()
      else
        table.remove(self.item.parameters.contents, idx)
      end
    end
    self:updateItemCounts(itm)
    self.dirty = true -- mark capacity as needing update
  end
  return rc
end

function provider:tryPutItem(req, test)
  if req.count <= 0 then return 0 end -- not actually inserting anything
  if self.filter and not self.filter(req) then return 0 end -- fails filter test
  local itm, idx
  for i, ii in pairs(self.item.parameters.contents) do -- find existing stack
    if root.itemDescriptorsMatch(req, ii, true) then itm, idx = ii, i break end
  end
  local count = req.count
  self:updateCapacity()
  local bitsLeft = self.driveParameters.capacity - self.item.parameters.bitsUsed
  if itm then
    count = math.min(count, bitsLeft)
    if count <= 0 then return 0 end -- can't fit any
    if not test then itm.count = itm.count + count end
  else
    count = math.min(count, bitsLeft - typeBits)
    if count <= 0 then return 0 end -- can't fit any
    if not test then
      itm = { name = req.name, parameters = req.parameters, count = count }
      table.insert(self.item.parameters.contents, itm)
    end
  end
  if not test then
    self:updateItemCounts(itm)
    self.dirty = true -- mark capacity as needing update
  end
    
  return count
end

function provider:updateCapacity()
  if not self.dirty then return end
  local bits = 0
  for k,item in pairs(self.item.parameters.contents) do
    bits = bits + typeBits + item.count
  end
  self.item.parameters.bitsUsed = bits
  self.dirty = nil
end
function provider:updateInfo(forceCapacity) -- refresh description
  if force then self.dirty = true end
  self:updateCapacity()
  local fDesc, pDesc = "", ""
  if self.item.parameters.filter and self.item.parameters.filter ~= "" then
    fDesc = table.concat({ "\n^green;Filter: ^blue;", self.item.parameters.filter })
  end
  if (self.item.parameters.priority or 0) ~= 0 then
    pDesc = table.concat({ "\n^green;Priority: ^blue;", self.item.parameters.priority  })
  end
  self.item.parameters.description = table.concat({
    self.driveParameters.description, "\n^green;Bytes used: ^blue;",
    math.ceil(self.item.parameters.bitsUsed / 8), " / ", math.ceil(self.driveParameters.capacity / 8), fDesc, pDesc
  })
end
function provider:updateFilter()
  if not self.item.parameters.filter then
    self.filter = nil
  else self.filter = itemutil.filter(self.item.parameters.filter) end
end

function provider:reseatIndices()
  local old, new, i = self.item.parameters.contents, { }, 1
  for k,v in pairs(old) do
    new[i] = v
    i = i + 1
  end
  self.item.parameters.contents = new
end

-- sweep through and combine all like stacks ("defrag")
function provider:rectify()
  local tl = { }
  for _, itm in pairs(self.item.parameters.contents) do
    local c = storagenet:getCacheFor(itm, true)
    tl[c] = (tl[c] or 0) + itm.count
  end
  self:updateItemCounts(tl, true) -- do this while we're here
  local ol, i = { }, 1
  for sc, count in pairs(tl) do
    ol[i] = { name = sc.descriptor.name, parameters = sc.descriptor.parameters, count = count }
    i = i + 1
  end
  -- and reinstall
  self.item.parametes.contents = ol
  coroutine.yield() -- one per tick
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
    local sp = driveProviders[slot]
    if sp then sp:updateInfo() end -- update description
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
  if sp then
    sp:updateInfo(true)
    sp:disconnect()
  end -- kill provider
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
  sp:setPriority(priority)
  if filter == "" then filter = nil end
  sp.item.parameters.filter = filter
  sp:updateFilter()
  sp:updateInfo()
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
    sp:updateInfo(true) -- give correct description
    sp:disconnect()
    world.spawnItem(sp.item, pos)
  end
end
