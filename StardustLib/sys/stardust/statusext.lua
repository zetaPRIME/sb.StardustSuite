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

local currentDamageRequest

local _applyDamageRequest = applyDamageRequest
function applyDamageRequest(damageRequest)
  currentDamageRequest = damageRequest
  do -- resparth the F r ackle
    local se = { }
    for _, s in pairs(damageRequest.statusEffects) do
      s = decodeStatus(s)
      if type(s) == "string" then table.insert(se, s)
      elseif s.effect then table.insert(se, s)
      elseif s.tag then (tagFunc[s.tag] or nf)(damageRequest, s) end
    end
    damageRequest.statusEffects = se
  end
  
  if isSpaceMonster and damageRequest.spaceDamageBonus then
    damageRequest.damage = damageRequest.damage * 3
  end
  
  damageRequest = querySelf("stardustlib:modifyDamageTaken", damageRequest) or damageRequest
  currentDamageRequest = damageRequest
  local res = _applyDamageRequest(damageRequest)
  
  --
  
  currentDamageRequest = nil
  return res
end

-- we're overriding knockbackMomentum because it'll work on all entity types this way
local _knockbackMomentum = knockbackMomentum
function knockbackMomentum(vec)
  local kb = _knockbackMomentum(vec)
  
  if (currentDamageRequest and currentDamageRequest.impulse) then
    kb = vec2.add(kb, currentDamageRequest.impulse)
  end
  
  return kb
end



function tagFunc:antiSpace(tag)
  self.spaceDamageBonus = true
end
tagFunc.spaceDamageBonus = tagFunc.antiSpace

function tagFunc:impulse(tag)
  local v = tag.vec or tag.vector
  if not v then return nil end
  self.impulse = vec2.add(self.impulse or {0, 0}, vec2.mul(v, (1 - status.stat("grit"))))
end

function tagFunc:rawImpulse(tag)
  local v = tag.vec or tag.vector
  if not v then return nil end
  self.impulse = vec2.add(self.impulse or {0, 0}, v)
end
