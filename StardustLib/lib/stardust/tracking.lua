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
  local ctProto = { }
  ctProto.__index = ctProto
  
  ctProto.onDisconnect = nullFunc
  function ctProto:disconnect()
    if self.dead then return end -- already done
    self.dead = true
    self:onDisconnect()
    active[self] = nil
    self.hook.active[self] = nil
  end
  
  ctProto.onUpdate = nullFunc
  
  -- TODO getContents etc.
  
  function containerTracker(id)
    if not id or not world.containerSize(id) then return end -- nothing here
    local ct = setmetatable({ id = id }, ctProto)
    
    world.callScriptedEntity(id, "require", "/lib/stardust/injects/containerhook.lua")
    ct.hook = world.callScriptedEntity(id, "$$cthook.get")
    if not ct.hook then return end -- error installing
    
    active[ct] = true
    ct.hook.active[ct] = true
    
    return ct
  end
end
