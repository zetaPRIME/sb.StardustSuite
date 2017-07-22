function playerextInit()
  if status.stat("playerextActive") == 1027.0 then return end
  --if status.getPersistentEffects("stardustlib:playerext") then return nil end
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
local _doneInit = false
function update(dt)
  if _update then _update(dt) end
  if not _doneInit then
    _doneInit = true
    playerextInit()
  end
  
  -- NaN protection for velocity
  local v = mcontroller.velocity()
  if v[1] ~= v[1] or v[2] ~= v[2] then
    mcontroller.setVelocity({0, 0})
  end
end
