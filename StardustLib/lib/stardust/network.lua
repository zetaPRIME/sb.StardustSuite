-- StardustLib.Network
require "/lib/stardust/interop.lua"

do
  local network = { } _ENV.network = network
  
  local poolProto = { }
  local poolMeta = { __index = poolProto }
  
  local function newPool(pool)
    return setmetatable(pool or { }, poolMeta)
  end
  
  function poolProto:delta(old)
    if not old then return { added = self, removed = newPool() } end
    local add, rem = newPool(), newPool()
    for id in pairs(self) do if not old[id] then add[id] = id end end
    for id in pairs(old) do if not self[id] then rem[id] = id end end
    return { added = add, removed = rem }
  end
  
  local tagCache = { }
  local untagged = { }
  local function getTags(id)
    local c = tagCache[id]
    if c then return c end
    c = world.getObjectParameter(id, "networkTags") or untagged
    tagCache[id] = c
    return c
  end
  
  local function checkPoolStep(id, pool, checked, searchTag)
    if checked[id] then return nil end
    checked[id] = true
    if (not searchTag) or getTags(id)[searchTag] then pool[id] = id end
    
    -- assemble connection pool
    local cp = { }
    for i = 0, world.callScriptedEntity(id, "object.inputNodeCount") - 1 do
      for k,v in pairs(world.callScriptedEntity(id, "object.getInputNodeIds", i)) do
        cp[k] = v
      end
    end
    for i = 0, world.callScriptedEntity(id, "object.outputNodeCount") - 1 do
      for k,v in pairs(world.callScriptedEntity(id, "object.getOutputNodeIds", i)) do
        cp[k] = v
      end
    end
    
    -- and loop through to check
    for k,v in pairs(cp) do
      if world.getObjectParameter(k, "isNetworkRelay") then
        checkPoolStep(k, pool, checked, searchTag)
      elseif searchTag then
        local tags = getTags(k)
        if tags[searchTag] then
          pool[k] = k
        end
      else
        pool[k] = k
      end
    end
  end
  
  function network.getPool(startId, searchTag)
    tagCache = { } -- reset cache in case of ID reuse
    local pool, checked = newPool(), { }
    if not startId then startId = entity.id() end
    if not world.entityExists(startId) or world.entityType(startId) ~= "object" then return pool end
    checkPoolStep(startId, pool, checked, searchTag)
    return pool
  end
  
  function network.narrowPool(pool, searchTag)
    local poolOut = newPool()
    for id in pairs(pool) do
      local tags = getTags(id)
      if (not searchTag and tags == untagged) or tags[searchTag] then -- allow empty search to find untagged pool items
        poolOut[id] = id
      end
    end
    return poolOut
  end
  poolProto.tagged = network.narrowPool
end
