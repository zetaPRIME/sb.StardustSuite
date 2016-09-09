function init()
  local newItem = item.descriptor()
  newItem.name = "startech:" .. newItem.name
  item.setCount(0)
  world.spawnItem(newItem, world.entityPosition(activeItem.ownerEntityId()))
end
