require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/itemutil.lua"
require "/lib/stardust/tracking.lua"

storagenet = { }

local provider = { }
local sp

-- forward declarations
local tryHookUp

local function phOnUpdate(self)
  if self.blockUpdate then return end -- already being taken care of
  object.say("update hook #" .. self.tcount)
  self.tcount = self.tcount + 1
  self.sp:clearItemCounts()
  self.sp:updateItemCounts(world.containerItems(self.id))
end
local function phOnDisconnect(self)
  self.sp:disconnect()
end

function provider:onConnect(id)
  sp = self
  self.id = id
  local ct = containerTracker(id)
  self.ct = ct
  ct.sp = self
  ct.onUpdate = phOnUpdate
  ct.onDisconnect = phOnDisconnect
  
  -- testing
  ct.tcount = 1
  
  self:updateItemCounts(world.containerItems(id))
end

function provider:onDisconnect()
  self.ct:disconnect()
  sp = nil
end

function storagenet:onConnect()
  tryHookUp()
end

function provider:tryPutItem(req, test)
  if req.count <= 0 then return 0 end -- nothing to insert
  if self.filter and not self.filter(req) then return 0 end -- excluded
  
  local leftover
  if not test then
    self.ct.blockUpdate = true
    leftover = world.containerAddItems(self.id, req)
    self.ct.blockUpdate = nil
  end
  if not leftover then leftover = { name = req.name, parameters = req.parameters, count = 0 } end
  if not test then self:updateItemCounts(leftover) end
  return req.count - leftover.count
end

function provider:tryTakeItem(req, test)
  if req.count <= 0 then return 0 end -- not requesting any
  local avail = world.containerAvailable(self.id, req)
  local count = math.min(req.count, avail)
  
  if not test then
    self.ct.blockUpdate = true
    world.containerConsume(self.id, { name = req.name, parameters = req.parameters, count = count })
    self.ct.blockUpdate = nil
    self:updateItemCounts { name = req.name, parameters = req.parameters, count = avail - count }
  end
  
  return count
end

local orientations = {
  { 0, -1 },
  { -1, 0 },
  { 0, 1 },
  { 1, 0 }
}
local orientName = { "down", "left", "up", "right" }

tryHookUp = function()
  if not storagenet.connected then return end -- nope
  local spos = vec2.add(entity.position(), orientations[storage.orientation])
  local id = world.objectAt(spos)
  if not id or not world.containerSize(id) then -- nothing to hook up to
    if sp then sp:disconnect() end -- clear if present
    return
  end
  if sp and sp.id ~= id then sp:disconnect() end -- different container? yeet
  storagenet:registerStorage(provider, id)
end

function setOrientation(o)
  storage.orientation = o
  tryHookUp()
end

function setPriority(p)
  storage.priority = p
  if sp then sp:setPriority(p) end
end










-- -- --

function init()
  if not storage.orientation then storage.orientation = 1 end
  if not storage.priority then storage.priority = 0 end
  object.setAnimationParameter("orientation", storage.orientation)
  
  object.setInteractive(false)
end
