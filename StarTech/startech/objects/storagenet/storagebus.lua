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
  self.sp:refreshCounts()
end
local function phOnDisconnect(self)
  self.sp:disconnect()
end

function provider:onConnect(id)
  sp = self
  self.id = id
  local cp = containerProxy(id)
  self.cp = cp
  cp.sp = self
  cp.onUpdate = phOnUpdate
  cp.onDisconnect = phOnDisconnect
  
  self.filter = storage.filter and itemutil.filter(storage.filter) or nil
  
  self:refreshCounts()
end

function provider:onDisconnect()
  self.cp:disconnect()
  sp = nil
end

function provider:refreshCounts()
  local old = self.contentsCache or { }
  local new = self.cp:contents()
  
  local tl = { } -- tracking list
  for _,itm in pairs(old) do
    tl[storagenet:getCacheFor(itm, true)] = 0
  end
  for _,itm in pairs(new) do
    local c = storagenet:getCacheFor(itm, true)
    tl[c] = (tl[c] or 0) + itm.count
  end
  self:updateItemCounts(tl, true)
  
  self.contentsCache = new
end

function storagenet:onConnect()
  tryHookUp()
end

function provider:tryPutItem(req, test)
  if req.count <= 0 then return 0 end -- nothing to insert
  if self.filter and not self.filter(req) then return 0 end -- excluded
  
  local count = math.min(world.containerItemsCanFit(self.id, req), req.count)
  if not test then
    --self.cp:blockNextUpdate()
    self.cp:insert(req)
  end
  if not test then self:updateItemCounts { name = req.name, parameters = req.parameters, count = world.containerAvailable(self.id, req) } end
  return count
end

function provider:tryTakeItem(req, test)
  if req.count <= 0 then return 0 end -- not requesting any
  local avail = self.cp:amountOf(req)
  local count = math.min(req.count, avail)
  
  if not test then
    --self.cp:blockNextUpdate()
    self.cp:consume { name = req.name, parameters = req.parameters, count = count }
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
  object.setAnimationParameter("orientation", storage.orientation)
  tryHookUp()
end

function setPriority(p)
  storage.priority = p
  if sp then sp:setPriority(p) end
end

function setFilter(f)
  if f == "" then f = nil end
  storage.filter = f
  if sp then sp.filter = f and itemutil.filter(f) or nil end
end

-- -- --

local svc = { }

function svc.wrenchInteract(msg, isLocal, player, shiftHeld)
  if shiftHeld then
    return {
      interact = {
        id = entity.id(),
        type = config.getParameter("interactAction"),
        config = { gui = { }, scripts = {"/metagui.lua"}, config = "startech:storagebus.config" }
      }
    }
  else
    local dl = {"v","<","^",">"}
    setOrientation((storage.orientation % 4) + 1)
    object.say(dl[storage.orientation])
  end
end

function svc.getInfo() return { filter = storage.filter or "", priority = storage.priority } end
function svc.setInfo(msg, isLocal, filter, priority)
  setPriority(priority)
  local pr = "Priority set: " .. storage.priority .. "\n"
  if filter == "" then
    setFilter()
    object.say(pr .. "Filter cleared")
  else
    setFilter(filter)
    object.say(pr .. "Filter set: " .. filter)
  end
end

-- -- --

function init()
  if not storage.orientation then storage.orientation = 1 end
  if not storage.priority then storage.priority = 0 end
  object.setAnimationParameter("orientation", storage.orientation)
  
  object.setInteractive(false)
  
  for k, v in pairs(svc) do message.setHandler(k, v) end
end
