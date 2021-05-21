local allowedWorldTypes = {
  ancientgateway = true,
}

function playSound(s)
  if type(s) ~= "table" then s = {s} end
  world.spawnProjectile("stationpartsound", entity.position(), entity.id(), {0, 0}, false, {
    periodicActions = { {
      time = 0, ["repeat"] = false, action = "sound", options = s
    } }
  })
end

function init()
  local owner = config.getParameter "owner"
  if not owner then return stagehand.die() end
  
  if allowedWorldTypes[world.type()] and world.isTileProtected(entity.position()) then
    world.sendEntityMessage(owner, "startech:consumeLiberator")
    world.setTileProtection(0, false)
    
    playSound "/sfx/interface/playerstation_place1.ogg"
    playSound "/sfx/objects/essencechest_open1.ogg"
    playSound "/sfx/gun/erchiuseyebeam_start.ogg"
    playSound "/sfx/gun/erchiuseyebeam_start.ogg"
  else
    playSound "/sfx/interface/nav_insufficient_fuel.ogg"
  end
  stagehand.die()
end
