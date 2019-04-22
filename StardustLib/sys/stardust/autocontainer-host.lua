--


function msg(txt)
  world.sendEntityMessage(pane.playerEntityId(), "playerext:message", txt)
end

function init()
  --
  --world.sendEntityMessage(pane.playerEntityId(), "playerext:message", "test: " .. (world.getObjectParameter(pane.containerEntityId(), "uiConfig") or "nil"))
  --[[local c = world.containerItems(pane.containerEntityId())
  local m = "items: "
  for k,v in pairs(c) do
    m = m .. v.name .. " "
  end
  msg(m)==]]
  cId = pane.containerEntityId()
  
  local p = { gui = { } }
  p.containerId = cId
  --p.openWithInventory = true
  p.gui.panefeature = {
    type = "panefeature",
    --anchor = "CenterBottom"
    --offset = { 20, 0 }
  }
  p.gui.base = {
    type = "background",
    fileFooter = "/sys/stardust/nothing.png?scalenearest=128;192?replace=00000000=000000?fade=7f7fff=1"
  }
  p.scripts = { "/sys/stardust/autocontainer-guest.lua" }
  
  status.setStatusProperty("stardust.containerPaneSyncId", cId)
  player.interact("ScriptPane", p)
  --player.interact("Container", "/startech/interface/storagenet/terminal.config", cId)
  
end

function update()
  if status.statusProperty("stardust.containerPaneSyncId") ~= cId then pane.dismiss() end
end

function uninit()
  if status.statusProperty("stardust.containerPaneSyncId") == cId then status.setStatusProperty("stardust.containerPaneSyncId", nil) end
end
