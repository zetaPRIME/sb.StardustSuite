-- sharedTable: centralized table smuggling made clean and easy

local bkey = "::sharedTable"
local base = getmetatable''[bkey]
if not base then
  base = { }
  getmetatable''[bkey] = base
end

-- usage:
-- local ipc = sharedTable "modname:whatever"
function sharedTable(key)
  local t = base[key]
  if not t then
    t = { }
    base[key] = t
  end
  return t
end
