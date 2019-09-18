--
require "/scripts/util.lua"
require "/lib/stardust/json.lua"

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

local pfx = "::"
local function decodeStatus(s)
  if string.sub(s.effect, 1, 2) ~= pfx then return s end
  return json.decode(string.sub(s.effect, 3, -1))
end

local function nf() end
local tagFunc = { }

local _applyDamageRequest = applyDamageRequest
function applyDamageRequest(damageRequest)
  do -- resparth the F r ackle
    local se = { }
    for _, s in pairs(damageRequest.statusEffects) do
      s = decodeStatus(s)
      if type(s) == "string" then table.insert(se, s)
      elseif s.effect then table.insert(se, s)
      elseif s.tag then (tagFunc[s.tag] or nf)(s, damageRequest) end
    end
    damageRequest.statusEffects = se
  end
  
  if isSpaceMonster and damageRequest.spaceDamageBonus then
    damageRequest.damage = damageRequest.damage * 3
  end
  
  damageRequest = querySelf("stardustlib:modifyDamageTaken", damageRequest) or damageRequest
  local res = _applyDamageRequest(damageRequest)
  
  --
  
  return res
end


function tagFunc.spaceDamageBonus(tag, req)
  req.spaceDamageBonus = true
end
