-- StardustLib.Mechanism

do
  mechanism = {}
  
  local function isWrench(item)
    if not item then return false end
    if item.parameters.isWrench then return true end
    if root.itemConfig(item.name).config.isWrench then return true end
    return false
  end
  
  function mechanism.entityHoldingWrench(entityId)
    if not world.entityExists(entityId) then return false end
    return isWrench(world.entityHandItemDescriptor(entityId, "primary")) or isWrench(world.entityHandItemDescriptor(entityId, "alt"))
  end
  
  
end
