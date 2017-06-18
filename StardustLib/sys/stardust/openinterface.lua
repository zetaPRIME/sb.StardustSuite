-- simple stub to open a defined interface, then set the swap slot item back to what it was before
function update(dt, fireMode, shiftHeld, moves)
  local info = config.getParameter("info") or {}
  if type(info) ~= "table" then info = {config = info} end
  activeItem.setHoldingItem(false)
  activeItem.interact(info.interactionType or "ScriptPane", info.config or "/sys/stardust/tablet/tablet.ui.config", activeItem.ownerEntityId())
  player.setSwapSlotItem(config.getParameter("restore") or {name="",count=0,parameters={}})
end
