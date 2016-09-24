function playerextInit()
  if status.stat("playerextActive") ~= 0 then return end
  world.spawnItem({
    name = "techcard", --"perfectlygenericitem",
    count = 1,
    parameters = {
      consumeOnPickup = true,
      pickupQuestTemplates = { "stardustlib:playerext" },
      shortdescription = "\n^#bf7fff;[ initializing StardustLib services ]\n^#00000000;"
    }
  }, entity.position())
end

local _update = update
function update(dt)
  if _update then _update(dt) end
  if not _doneInit then
    _doneInit = true
    playerextInit()
  end
end
