--
require "/scripts/util.lua"

local entityType = world.entityType(entity.id())
local isSpaceMonster == not not __spaceMonster

--[[local _applyDamageRequest = applyDamageRequest
function applyDamageRequest(damageRequest)
  sb.logInfo(util.tableToString(damageRequest))
  return _applyDamageRequest(damageRequest)
end]]
