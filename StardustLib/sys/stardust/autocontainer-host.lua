--


function msg(txt)
  world.sendEntityMessage(pane.playerEntityId(), "playerext:message", txt)
end

local btn = {
  file = "/metagui/ninepatch.png",
  frameSize = 10,
  height = 18,
  left = 4, right = 4
}
function btn:render(w)
  w = math.max(w, self.left + self.right + self.frameSize)
  local h = self.height
  local fs = self.frameSize
  local iw = w - (self.left + self.right)
  
  local seq = { }
  
  table.insert(seq, self.file .. ":1" )
  table.insert(seq, string.format("?scalebilinear=%f;1", iw/fs) )
  table.insert(seq, string.format("?border=%d;00000000", fs) )
  table.insert(seq, string.format("?crop=0;%d;%d;%d", fs, iw + (fs * 2), fs + h) )
  table.insert(seq, string.format("?blendscreen=%s:0", self.file) )
  table.insert(seq, string.format("?blendscreen=%s:2;%d;0", self.file, -(iw + fs)) )
  table.insert(seq, string.format("?crop=%d;%d;%d;%d", fs - self.left, 0, (iw + fs * 2) - (fs - self.right), h) )
  
  return table.concat(seq)
end

function init()
  --pane.dismiss()
  --
  --world.sendEntityMessage(pane.playerEntityId(), "playerext:message", "test: " .. (world.getObjectParameter(pane.containerEntityId(), "uiConfig") or "nil"))
  --[[local c = world.containerItems(pane.containerEntityId())
  local m = "items: "
  for k,v in pairs(c) do
    m = m .. v.name .. " "
  end
  msg(m)==]]
  cId = pane.containerEntityId()
  pId = player.id()
  
  local p = { gui = { } }
  p.containerId = cId
  p.openWithInventory = true
  p.gui.panefeature = {
    type = "panefeature",
    --anchor = "CenterBottom"
    --offset = { 20, 0 }
  }
  p.gui.base = {
    type = "background",
    --fileFooter = "/sys/stardust/nothing.png?scalenearest=128;192?blendscreen=/interface/crafting/bgselection6.png"
    fileFooter = btn:render(88)
  }
  p.scripts = { "/sys/stardust/autocontainer-guest.lua" }
  
  --status.setStatusProperty("stardust.containerPaneSyncId", cId)
  player.interact("ScriptPane", p)
  
  --message.setHandler("closeHost" .. cId, function() pane.dismiss() end)
  
  
  
  --player.interact("OpenContainer", { paneLayoutOverride = root.assetJson("/startech/interface/storagenet/terminal.config").gui }, 34)
  --player.interact("ScriptPane", "/startech/interface/storagenet/terminal.config", cId)
  --msg(itemGrid and "y" or "n")
  --[[for i = 1, 1000000 do
    world.containerItems(cId)
  end]]
  
end

function update()
  --if status.statusProperty("stardust.containerPaneSyncId") ~= cId then 
  --  pane.dismiss()
  --end
end

function uninit()
  world.sendEntityMessage(player.id(), "closeGuest" .. cId)
  --if status.statusProperty("stardust.containerPaneSyncId") == cId then status.setStatusProperty("stardust.containerPaneSyncId", nil) end
  --player.interact("OpenContainer", nil, cid)
  --player.interact("OpenContainer", nil, cid)
end
