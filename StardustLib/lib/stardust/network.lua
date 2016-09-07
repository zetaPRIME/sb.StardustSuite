-- StardustLib.Network
require "/lib/stardust/interop.lua"

do
  network = {}
  
  local function finalizePool(pool)
    local pt = {} -- use a template instead of actually adding members so pairs doesn't derp you up
    function pt.tagged(searchTag) return network.narrowPool(pool, searchTag) end
    
    setmetatable(pool, { __index = pt })
    return pool
  end
  
  local function checkPoolStep(id, pool, checked, searchTag)
    if checked[id] then return nil end
    checked[id] = true
    pool[id] = true
    
    -- assemble connection pool
    local cp = {}
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
    
    -- and loop through
    for k,v in pairs(cp) do
      if world.getObjectParameter(k, "isNetworkRelay") then
        checkPoolStep(k, pool, checked, searchTag)
      elseif searchTag then
        local tags = world.getObjectParameter(k, "networkTags")
        if tags and tags[searchTag] then
          pool[k] = true
        end
      else
        pool[k] = true
      end
    end
  end
  
  function network.getPool(startId, searchTag)
    local pool, checked = {}, {}
    if not startId then startId = entity.id() end
    if not world.entityExists(startId) or world.entityType(startId) ~= "object" then return {} end
    checkPoolStep(startId, pool, checked, searchTag)
    local poolOut, i = {}, 1
    for k,v in pairs(pool) do
      poolOut[i] = k
      i = i + 1
    end
    return finalizePool(poolOut)
  end
  
  function network.narrowPool(pool, searchTag)
    local poolOut = {}
    local i = 1
    for isrc = 1, #pool do
      local id = pool[isrc]
      local tags = world.getObjectParameter(id, "networkTags")
      if (tags and tags[searchTag]) or (not searchTags and not tags) then -- allow empty search to find non-networked pool items
        poolOut[i] = id
        i = i + 1
      end
    end
    return finalizePool(poolOut)
  end
end
