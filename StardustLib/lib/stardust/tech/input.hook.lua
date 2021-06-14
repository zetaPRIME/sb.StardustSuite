-- input hook - patches existing techs to provide inputs to outside

if _SBLOADED and _SBLOADED["/lib/stardust/tech/input.lua"] then return end -- abort if input lib already present
local oinput = _ENV.input
require "/lib/stardust/tech/input.lua"
local input = input -- take local copy
if oinput then _ENV.input = oinput end -- restore old table if one exists

local function hookUpdate()
  local _update = _ENV.update or function() end
  function _ENV.update(...)
    input.update(...)
    return _update(...)
  end
end

if sb then -- required during or after init
  hookUpdate()
else -- pre-init, metatable hook needed
  local omt = getmetatable(_ENV)
  local mt = { } setmetatable(_ENV, mt)
  
  function mt.__newindex(t,k,v)
    rawset(t,k,v)
    if k == "sb" then -- spring on internal tables being added pre-init
      setmetatable(_ENV, omt) -- restore original metatable
      hookUpdate() -- and hook
    end
  end
end
