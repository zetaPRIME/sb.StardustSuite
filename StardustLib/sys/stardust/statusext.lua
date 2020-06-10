--
require "/scripts/util.lua"
require "/lib/stardust/json.lua"

local entityId = entity.id()
local entityType = world.entityType(entityId)
local isSpaceMonster = not not __spaceMonster
local hasFU = root.hasTech("fuhealzone") -- quick and easy detection

local initDone
local _update = update
function update(...)
  if not initDone then initDone = true
    entityType = world.entityType(entityId) -- refresh this
    if entityType and entityType ~= "player" then -- inject entity-space code
      world.callScriptedEntity(entityId, "require", "/sys/stardust/entityext.lua")
    end
  end
  (_update or function() end)(...)
end

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

message.setHandler("stardustlib:damagedEntity", function(msg, isLocal, id, srcDmg, effDmg, kind)
  local leech = status.stat("stardustlib:leech", 0)
  status.modifyResource("health", effDmg * leech)
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
  do -- decode any encoded status effects
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

local elementalResistance = root.elementalResistance
function root.elementalResistance(type)
  if currentDamageRequest and currentDamageRequest.dmgTypes then
    return elementalResistance -- eh, why not.
  end
  return elementalResistance(type)
end

local stat = status.stat
function status.stat(s, default)
  if s ~= elementalResistance then return stat(s, default) end
  local types = currentDamageRequest.dmgTypes
  local r, acc = 0, 0
  for type, amt in pairs(types) do
    acc = acc + math.abs(amt)
    r = r + stat(elementalResistance(type)) * amt
  end
  if acc == 0 then return 0 end
  return r / acc
end

biFunc = { }
local evalFunction2 = root.evalFunction2
function root.evalFunction2(f, a, b)
  local fn = biFunc[f]
  if fn then return fn(a, b) end
  return evalFunction2(f, a, b)
end

do -- bivariate functions --
  --
  if hasFU then
    -- damage cap is high enough to be irrelevant
  else
    function biFunc.protection(dmg, def)
      dmg = dmg * (1.0 - def/100.0)
      if dmg <= 0 then return 0 end
      return math.max(1, dmg) -- if it does damage, always do at least 1.0
    end
  end
  --
end -- -- -- -- -- -- -- --

do -- tag functions --
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
  
  local dmgTypeFix = { physical = "plasma" }
  function tagFunc:dmgTypes(tag)
    local t = tag.types or tag.type or tag.t
    if not t then return nil end
    self.dmgTypes = self.dmgTypes or { }
    for k, v in pairs(t) do
      k = dmgTypeFix[k] or k
      self.dmgTypes[k] = (self.dmgTypes[k] or 0) + v
    end
  end
end -- -- -- -- -- --
