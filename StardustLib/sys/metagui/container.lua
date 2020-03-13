-- metaGUI universal container proxy

function init()
  inputcfg = world.getObjectParameter(pane.containerEntityId(), "ui")
  pane.sourceEntity = pane.containerEntityId
  require "/sys/metagui/build.lua"
end
