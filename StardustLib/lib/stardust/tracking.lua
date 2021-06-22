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
  
  -- Does what it says on the tin. Be careful, this will cause you to miss any changes that tick, not just your own!
  function cpProto:blockNextUpdate()
    self._block = true
    return self -- chainable, since you're probably operating on it
  end
  
  function cpProto:contents()
    return world.containerItems(self.id)
  end
  function cpProto:amountOf(req)
    return world.containerAvailable(self.id, { name = req.name, parameters = req.parameters, count = 1 })
  end
  
  function cpProto:insert(req, exact) -- returns number inserted
    local canFit = math.min(world.containerItemsCanFit(self.id, req), req.count)
    if exact and canFit < req.count then return 0 end
    world.containerAddItems(self.id, req)
    return canFit
  end
  function cpProto:consume(req, exact) -- returns number removed
    if exact then
      return world.containerConsume(req) and req.count or 0
    end
    local avail = math.min(self:amountOf(req), req.count)
    world.containerConsume { name = req.name, parameters = req.parameters, count = avail }
    return avail
  end
  
  --- --- ---
  
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
