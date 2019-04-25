---[[
setmetatable(_ENV, { __index = function(t,k)
  sb.logInfo("missing field "..k.." accessed")
  local f = function(...)
    local msg = "called "..k..":\n"..dump({...})
    sb.logInfo(msg)
    player.radioMessage({text=msg,messageId="scriptDbg",unique=false})
  end
  return nil -- f
end }) --]]

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function init()
  cId = config.getParameter("containerId")
  --local d = widget.getData("paneFeature")
  --sb.logInfo("stuff:\n" .. dump(o))
end

function openWithInventory()
   return true
end

function update()
  local ccid = status.statusProperty("stardust.containerPaneSyncId")
  if ccid ~= cId then
    pane.dismiss(false)
  end
end

function uninit()
  if status.statusProperty("stardust.containerPaneSyncId") == cId then status.setStatusProperty("stardust.containerPaneSyncId", nil) end
end
