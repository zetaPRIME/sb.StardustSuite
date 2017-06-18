--




function openInterface(info)
  player.setSwapSlotItem({
    name = "stardustlib:openinterface",
    count = 1,
    parameters = {
      info = info,
      restore = player.swapSlotItem()
    }
  })
end




local lst = "scroll.list"

local prefix = ""

function addItem(itm)
  local li = lst .. "." .. widget.addListItem(lst)
  widget.setText(li .. ".label", prefix .. itm.label)
  widget.registerMemberCallback(li .. ".buttonContainer", "click", function()
    openInterface(itm.pane)
  end)
  local btn = li .. ".buttonContainer." .. widget.addListItem(li .. ".buttonContainer") .. ".button"
  if itm.icon then
    local icn = itm.icon
    if icn:sub(1,1) ~= "/" then icn = "/quickbar/" .. icn end
    widget.setButtonOverlayImage(btn, itm.icon)
  end
end

function init()
  widget.clearListItems(lst)
  local items = root.assetJson("/quickbar/icons.json") or {}
  prefix = "^#7fff7f;"
  for k,v in pairs(items.priority or {}) do addItem(v) end
  if player.isAdmin() then
    prefix = "^#bf7fff;"
    for k,v in pairs(items.admin or {}) do addItem(v) end
  end
  prefix = ""
  for k,v in pairs(items.normal or {}) do addItem(v) end
end
