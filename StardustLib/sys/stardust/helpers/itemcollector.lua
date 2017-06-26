--

function update(dt)
  local target = config.getParameter("target")
  local radius = config.getParameter("radius") or 5
  local position = entity.position()
  
  local items = {}
  for k,id in pairs(world.itemDropQuery(position, radius)) do
    local itm = world.takeItemDrop(id, target);
    if itm then items[#items+1] = itm end
  end
  
  if target then
    world.sendEntityMessage(target, "playerext:giveItems", table.unpack(items))
  end
  
  stagehand.die()
end
