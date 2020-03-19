-- metaGUI stub
-- INCOMPLETE, DO NOT COPY YET
-- this file should never need to change and can therefore be included UNMODIFIED in other mods

function init() pane.dismiss()
  _mgcfg = root.assetJson("/panes.config").metaGUI
  if not _mgcfg then -- attempt to use fallback if metaGUI isn't present
    local fb = config.getParameter("fallback")
    if not fb then return player.confirm {
        paneLayout = "/interface/windowconfig/popup.config:paneLayout",
        icon = "/interface/errorpopup/erroricon.png",
        title = "metaGUI error",
        message = "Could not detect metaGUI/StardustLib, and interaction does not specify a fallback."
      } end
    if type(fb) ~= "table" or not fb[1] then fb = { "ScriptPane", fb } end
    player.interact(fb[1], fb[2], pane.sourceEntity())
  else
    require(_mgcfg.providerRoot .. "build.lua")
  end
  
  
end
