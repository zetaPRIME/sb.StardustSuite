-- StardustLib.Interop

do
  interop = {}
  -- okay, self gets clobbered, do this instead
  local _shared = {}
  shared = setmetatable({}, { __index = _shared })

  -- neat, compact function to futz with other entities' self table (can't do globals since _G is nil'd)
  function _shared._var(name, val, del)
    local prev = shared[name]
    if val or del then shared[name] = val end
    return prev
  end
  
  function _shared._get() return shared end
  function interop.getShared(id) return world.callScriptedEntity(id, "shared._get") or {} end
  --function interop.getShared(id) return world.callScriptedEntity(id, "interop.localShared") end
  function interop.localShared() return shared end
  
  -- fail=nil on callScriptedEntity instead of exception
  function interop.safeCall(id, func, ...)
    if not world.entityExists(id) then return nil end
    return world.callScriptedEntity(id, func, ...)
  end
  
  --function unpack(t, i) -- WHY IS THIS MISSING oh wait, it's table.unpack now
  --  i = i or 1
  --  if t[i] ~= nil then
  --    return t[i], unpack(t, i + 1)
  --  end
  --end
  
  function zpcall(func, ...)
    --local par = {...}
    --local res = {pcall(function() return func(unpack(par)) end)}
    local res = {pcall(func, ...)}
    --sb.logInfo("zpcall return " .. sb.print(res))
    if res[1] then return table.unpack(res, 2) end
    sb.logWarn(table.concat({ "Call failed: ", sb.print({table.unpack(res,2)}) }))
    return nil
  end
  
  function interop.hack(id) -- this is REALLY SILLY; returns a given entity's execution environment
    local s = pcall(world.callScriptedEntity, id, "require", "/lib/stardust/-inject.lua")
    if not s then return nil end -- not callable
    local henv = world.callScriptedEntity(id, "_renv")
    
    return henv
  end
  
end
