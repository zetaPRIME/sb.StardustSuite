-- MetaGUI container patch
-- Inserts functions necessary for dynamic container UI

if object and (world.containerSize(entity.id()) or 0) > 0 then
  local syncId = 0
  
  local observing = { }
  
  local ccname = config.getParameter("containerCallback", "containerCallback")
  local cc = _ENV[ccname] or function() end
  _ENV[ccname] = function(...) cc(...)
    syncId = syncId + 1
    -- actually do the thing
    
    for id in pairs(observing) do
      if world.entityType(id) ~= "player" then observing[id] = nil else
        world.sendEntityMessage(id, "metagui:containerUpdated", entity.id(), syncId)
      end
    end
  end
  
  message.setHandler("metagui:setObserving", function(msg, isLocal, id, f)
    observing[id] = f or nil
  end)
end
