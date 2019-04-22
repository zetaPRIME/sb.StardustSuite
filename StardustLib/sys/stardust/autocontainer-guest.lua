function init()
  cId = config.getParameter("containerId")
end

function update()
  if status.statusProperty("stardust.containerPaneSyncId") ~= cId then pane.dismiss() end
end

function uninit()
  if status.statusProperty("stardust.containerPaneSyncId") == cId then status.setStatusProperty("stardust.containerPaneSyncId", nil) end
end
