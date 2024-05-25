-- Modified metaGUI container stub
require "/lib/stardust/sharedtable.lua"
local ipc = sharedTable "metagui:ipc"

function init()
  if ipc._stardustui_chestopts then
    inputcfg = "stardustui:chestoptions"
    ipc._stardustui_chestopts = nil
  else
    inputcfg = "stardustui:chest"
  end
  pane.sourceEntity = pane.containerEntityId
  require(root.assetJson("/panes.config").metaGUI.providerRoot .. "build.lua")
end
