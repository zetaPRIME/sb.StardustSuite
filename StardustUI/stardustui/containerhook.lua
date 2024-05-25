-- monkey patch to keep track of any container being open

require "/lib/stardust/sharedtable.lua"
local ipc = sharedTable "stardustui:ipc"

local cid

local _init = init
function init(...)
  cid = pane.containerEntityId()
  ipc.openContainerId = cid
  --sb.logInfo("+ opened container " .. cid)
  if _init then return _init(...) end
end

local _uninit = uninit
function uninit(...)
  if ipc.openContainerId == cid then ipc.openContainerId = nil end
  --sb.logInfo("- closed container " .. cid)
  if _uninit then return _uninit(...) end
end
