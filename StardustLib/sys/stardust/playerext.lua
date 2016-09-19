

setmetatable(_ENV, { __index = function(t,k)
  sb.logInfo("missing field "..k.." accessed")
  local f = function(...)
    local msg = "called "..k..":\n"..dump({...})
    sb.logInfo(msg)
    player.radioMessage({text=msg,messageId="scriptDbg",unique=false})
  end
  return nil -- f
end })

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

function update()
  --
end

function init()
  liveMsg("WIP, please ignore for now")
  quest.fail()
  --liveMsg(dump(player.essentialItem("painttool")))
  --player.giveEssentialItem("painttool", {
  --  name = "painttool",
  --  count = 1,
  --  parameters = {}
  --})
end

function liveMsg(msg)
  player.radioMessage({text=msg,messageId="scriptDbg",unique=false})
end

