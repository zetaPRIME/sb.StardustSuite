require "/scripts/util.lua"

local function nullFunc() end

local active = { }
local hooked
local function spawnhooks()
  if hooked then return end
  hooked = true
  
  local _uninit = _ENV.uninit or nullFunc
  _ENV.uninit = function()
    for t in pairs(active) do t:disconnect() end
    _uninit()
  end
end

do
  local cpProto = { }
  cpProto.__index = cpProto
  
  cpProto.onDisconnect = nullFunc
  function cpProto:disconnect()
    if self.dead then return end -- already done
    self.dead = true
    self:onDisconnect()
    active[self] = nil
    self.hook.active[self] = nil
  end
  
  cpProto.onUpdate = nullFunc
  function cpProto:sendUpdate()
    if self._block then
      self._block = nil
      return
    end
    self:onUpdate()
  end
  function cpProto:blockNextUpdate()
    self._block = true
    return self
  end
  
  -- TODO getContents etc.
  
  function containerProxy(id)
    if not id or not world.containerSize(id) then return end -- nothing here
    local cp = setmetatable({ id = id }, cpProto)
    
    world.callScriptedEntity(id, "require", "/lib/stardust/injects/containerhook.lua")
    cp.hook = world.callScriptedEntity(id, "$$cphook.get")
    if not cp.hook then return end -- error installing
    
    active[cp] = true
    cp.hook.active[cp] = true
    
    return cp
  end
end
