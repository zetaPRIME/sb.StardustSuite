-- metaGUI universal container proxy

function init()
  inputcfg = world.getObjectParameter(pane.containerEntityId(), "ui")
  inputdata = world.getObjectParameter(pane.containerEntityId(), "uiData")
  pane.sourceEntity = pane.containerEntityId
  require "/sys/metagui/build.lua"
end
