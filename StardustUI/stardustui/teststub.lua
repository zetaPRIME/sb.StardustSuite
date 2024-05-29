require "/lib/stardust/sharedtable.lua"

local ipc = sharedTable "stardustui:ipc"
ipc._addm "stub load"

function init()
  chat.addMessage "stub init exec"
  pane.dismiss()
end
