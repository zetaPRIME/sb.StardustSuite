local _update = update

function update(dt)
    _update(dt)
    --status.setResource("energy", 50)
    --if player then sb.logInfo("Player table accessible")
    --else sb.logInfo("No player table :(") end
end

local _init = init
function init()
    _init()
    local p_utf8 = _ENV.utf8
    _ENV.utf8 = false
    sb.logInfo("player _ENV:\n"..dump(_ENV))
    _ENV.utf8 = p_utf8
end

function dump(o, ind)
  if not ind then ind = 2 end
  local pfx, epfx = "", ""
  for i=1,ind do pfx = pfx .. " " end
  for i=3,ind do epfx = epfx .. " " end
  if type(o) == 'table' then
    local s = '{\n'
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. pfx .. '['..k..'] = ' .. dump(v, ind+2) .. ',\n'
    end
    return s .. epfx .. '}'
  else
    return tostring(o)
  end
end

setmetatable(_ENV, { __index = function(t,k)
  sb.logInfo("missing field "..k.." accessed")
  local f = function(...)
    sb.logInfo("called")
  end
  return nil -- f
end })
