-- simple stub to perform an action, then set the swap slot item back to what it was before
function update(dt, fireMode, shiftHeld, moves)
  --local info = config.getParameter("info") or {}
  --if type(info) ~= "table" then info = {config = info} end
  --activeItem.interact(info.interactionType or "ScriptPane", info.config or "/sys/stardust/tablet/tablet.ui.config", activeItem.ownerEntityId())
  local mode = config.getParameter("mode") or ""
  
  if mode == "checkShift" then
    status.setStatusProperty("stardustlib:shiftHeld", shiftHeld)
  elseif mode == "shiftableGive" then
    if shiftHeld then
      player.giveItem(config.getParameter("restore") or {name="",count=0,parameters={}})
      player.setSwapSlotItem({name="",count=0,parameters={}})
      return nil
    end
  end
  
  --activeItem.setHoldingItem(false)
  player.setSwapSlotItem(config.getParameter("restore") or {name="",count=0,parameters={}})
end
