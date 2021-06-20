--
require "/scripts/util.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/tasks.lua"
require "/lib/stardust/interop.lua"
--require "/lib/stardust/itemutil.lua"

local nullFunc = function() end

local processes = taskQueue()

local devices = { }
--[[ map<objId, device>
  device = {
    handle
    storage = map<storageProvider, true>
  }
]]

local itemCache = { }
--[[ map<itemname, cache>
  cache = {
    types = {
      [1] = {
        descriptor = <item descriptor>
        storage = map<provider, count>
      }
      ...
    }
  }
]]

local handleProto = { }
local handleMeta = { __index = handleProto }
handleProto.connected = true -- indicator

-- event stubs
handleProto.onConnect = nullFunc
handleProto.onDisconnect = nullFunc

function handleProto:disconnect()
  local dev = devices[self.id]
  if dev then
    for sp in pairs(dev.storage) do
      sp:disconnect()
    end
    
    devices[self.id] = nil
  end
  self:onDisconnect()
  setmetatable(self, nil) -- deactivate
end



----------------------------------------------------------------

function init()
  
  object.setInteractive(false) -- disable container interface
  
  -- set all outputs positive for chunkloading purposes
  for i=1, object.outputNodeCount() do object.setOutputNodeLevel(i-1, true) end
  
end

function update(dt)
  processes:run()
end

processes:spawn("networkManager", function()
  --
  local pool
  
  while true do
    local old = pool
    pool = network.getPool(nil, "startech:storagenet.device")
    local delta = pool:delta(old)
    
    for id in pairs(delta.removed) do
      local dev = devices[id]
      if dev then dev.handle:disconnect() end
    end
    
    for id in pairs(delta.added) do
      local env = interop.hack(id)
      if env then
        if not env.storagenet then env.storagenet = { } end
        local handle = env.storagenet
        setmetatable(handle, handleMeta)
        handle.id = id
        handle.env = env
        
        local dev = { handle = handle, storage = { } }
        devices[id] = dev
        
        handle:onConnect()
      end
    end
    
    
    util.wait(5)
  end
end)
