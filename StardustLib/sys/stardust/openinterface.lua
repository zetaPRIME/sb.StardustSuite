-- simple stub to open a defined interface, then set the swap slot item back to what it was before
function update(dt, fireMode, shiftHeld, moves)
  local info = config.getParameter("info") or {}
  if type(info) ~= "table" then info = {config = info} end
  activeItem.setHoldingItem(false)

  -- Store accessible configuration.
  quickbarConfig = type(info.config) == "table" and info.config or root.assetJson(info.config)

  -- Allow dynamic modification of the loaded configuration through global 'quickbarConfig'.
  if quickbarConfig and info.loadScript then
    local status, err = pcall(function() require(info.loadScript) end)
    if not status then
      sb.logError("Quickbar: Failed loading '%s':\n%s", info.loadScript, err)
    end
  end

  activeItem.interact(info.interactionType or "ScriptPane", quickbarConfig or "/sys/stardust/tablet/tablet.ui.config", activeItem.ownerEntityId())
  player.setSwapSlotItem(config.getParameter("restore") or {name="",count=0,parameters={}})
end
