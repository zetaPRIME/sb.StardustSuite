--
require "/scripts/util.lua"

local entityType = world.entityType(entity.id())
local isSpaceMonster = not not __spaceMonster

local function resultOf(promise)
  err = nil
  if not promise:finished() then return promise end
  if not promise:succeeded() then
    err = promise:error()
    return nil
  end
  return promise:result()
end

local function querySelf(cmd, ...)
  return resultOf(world.sendEntityMessage(entity.id(), cmd, ...))
end

message.setHandler("stardustlib:getStatusImbue", function()
  local imbue = { }
  message.setHandler("stardustlib:statusImbueQueryReply", function(_, _, tbl) util.appendLists(imbue, tbl or { }) end)
  world.sendEntityMessage(entity.id(), "stardustlib:statusImbueQuery") -- synchronous gather
  message.setHandler("stardustlib:statusImbueQueryReply", nil) -- unhook handler
  return imbue
end)

--[[local _applyDamageRequest = applyDamageRequest
function applyDamageRequest(damageRequest)
  sb.logInfo(util.tableToString(damageRequest))
  return _applyDamageRequest(damageRequest)
end]]
