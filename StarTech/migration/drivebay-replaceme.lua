function update()
  --if true then return nil end
  local id = entity.id()
  local par = {}
  par.dir = object.direction()
  par.pos = object.position()
  par.itm = world.containerItems(id)
  world.containerTakeAll(id)
  
  object.smash(true)
  local sh = world.spawnStagehand(par.pos, "drivebayreplacer")
  world.callScriptedEntity(sh, "setupReplace", par)
end
