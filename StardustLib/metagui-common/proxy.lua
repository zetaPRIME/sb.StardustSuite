-- metaGUI proxy
function init() pane.dismiss()
  _mgcfg = root.assetJson("/panes.config").metaGUI
  if not _mgcfg then -- use fallback if metaGUI isn't present
    local inta = world.getObjectParameter(pane.sourceEntity(), "fallbackInteractAction")
    local intd = world.getObjectParameter(pane.sourceEntity(), "fallbackInteractData")
    if not inta or not intd then return nil end
    player.interact(inta, intd, pane.sourceEntity())
  else
    -- stuff, eventually
  end
end
