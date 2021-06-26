-- Modified metaGUI container stub

function init()
  inputcfg = "stardustui:chest"
  pane.sourceEntity = pane.containerEntityId
  require(root.assetJson("/panes.config").metaGUI.providerRoot .. "build.lua")
end
