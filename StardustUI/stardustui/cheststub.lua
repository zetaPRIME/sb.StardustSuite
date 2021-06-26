-- Modified metaGUI container stub

function init()
  local ipc = getmetatable ''.metagui_ipc
  if ipc and ipc._stardustui_chestopts then
    inputcfg = "stardustui:chestoptions"
    ipc._stardustui_chestopts = nil
  else
    inputcfg = "stardustui:chest"
  end
  pane.sourceEntity = pane.containerEntityId
  require(root.assetJson("/panes.config").metaGUI.providerRoot .. "build.lua")
end
