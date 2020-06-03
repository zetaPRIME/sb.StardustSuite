--
require "/sys/stardust/skilltree/skilltree.lua"

local function loadItem()
  local nf = player.equippedItem("chest")
  if (nf or { }).name ~= "startech:nanofield" then return pane.dismiss() end
  return nf
end

local function saveItem(itm)
  player.setEquippedItem("chest", itm)
end

function init()
  skilltree.initFromItem(treeCanvas, loadItem, saveItem)
  
end
