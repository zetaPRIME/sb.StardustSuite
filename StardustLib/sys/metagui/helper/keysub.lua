-- hmm.

local ipc = getmetatable ''.metagui_ipc
local ks = ipc.keysub
keyEvent = ks.keyEvent

local wid
function init()
  wid = player.worldId()
end

function update()
  if ipc.keysub ~= ks then return kill() end
  if player.worldId() ~= wid then return kill() end
  widget.focus("canvas")
end

function keyEvent(key, down)
  ks.keyEvent(key, down, char)
end

local killed = false
function kill() killed = true pane.dismiss() end

function uninit()
  if not killed then -- assume esc pressed
    if ks.escEvent then ks.escEvent() end
  end
end
