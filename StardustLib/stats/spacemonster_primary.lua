require "/scripts/vec2.lua"
require "/scripts/util.lua"
require "/scripts/status.lua"

function init()
  self.damageFlashTime = 0

  message.setHandler("applyStatusEffect", function(_, _, effectConfig, duration, sourceEntityId)
      status.addEphemeralEffect(effectConfig, duration, sourceEntityId)
    end)

  local reboundFactor = status.statusProperty("onHitReboundFactor", 0.65)
  local minReboundSpeed = status.statusProperty("onHitMinReboundSpeed", 13)

  self.damageListener = damageListener("inflictedHits", function(notifications)
      for _, notification in ipairs(notifications) do
        if notification.damageSourceKind == "impact" then
          local entityVelocity = world.entityVelocity(notification.targetEntityId)
          local entityPosition = world.entityPosition(notification.targetEntityId)
          if entityVelocity and entityPosition then
            local relativeVelocity = vec2.sub(vec2.mul(entityVelocity, 0.85), mcontroller.velocity())
            local relativePosition = world.distance(mcontroller.position(), entityPosition)
            local angleDiff = util.angleDiff(vec2.angle(relativeVelocity), vec2.angle(relativePosition))
            if math.abs(angleDiff) < math.pi / 2 then
              local reboundSpeed = math.max(minReboundSpeed, vec2.mag(relativeVelocity) * reboundFactor)
              local bounceVelocity = vec2.add(relativeVelocity, vec2.withAngle(vec2.angle(relativePosition), reboundSpeed))
              mcontroller.setVelocity(vec2.add(mcontroller.velocity(), bounceVelocity))
            end
          end
        end
      end
    end)
  
  if root.hasTech("stardustlib:stub1") then -- stardustlib shim
    __spaceMonster = true
    require "/sys/stardust/statusext.lua"
  end
end

function applyDamageRequest(damageRequest)
  if world.getProperty("nonCombat") then
    return {}
  end

  local damage = 0
  if damageRequest.damageType == "Damage" or damageRequest.damageType == "Knockback" then
    damage = damage + root.evalFunction2("protection", damageRequest.damage, status.stat("protection"))
  elseif damageRequest.damageType == "IgnoresDef" then
    damage = damage + damageRequest.damage
  elseif damageRequest.damageType == "Environment" then
    return {}
  elseif damageRequest.damageType == "Status" then
    -- only apply status effects
    status.addEphemeralEffects(damageRequest.statusEffects, damageRequest.sourceEntityId)
    return {}
  end

  if status.resourcePositive("shieldHealth") then
    local shieldAbsorb = math.min(damage, status.resource("shieldHealth"))
    status.modifyResource("shieldHealth", -shieldAbsorb)
    damage = damage - shieldAbsorb
  end

  local hitType = damageRequest.hitType
  local elementalStat = root.elementalResistance(damageRequest.damageSourceKind)
  local resistance = status.stat(elementalStat)
  damage = damage - (resistance * damage)
  if resistance ~= 0 and damage > 0 then
    hitType = resistance > 0 and "weakhit" or "stronghit"
  end

  local healthLost = math.min(damage, status.resource("health"))
  if healthLost > 0 and damageRequest.damageType ~= "Knockback" then
    status.modifyResource("health", -healthLost)
    if hitType == "stronghit" then
      self.damageFlashTime = 0.07
      self.damageFlashType = "strong"
    elseif hitType == "weakhit" then
      self.damageFlashTime = 0.07
      self.damageFlashType = "weak"
    else
      self.damageFlashTime = 0.07
      self.damageFlashType = "default"
    end
  end

  status.addEphemeralEffects(damageRequest.statusEffects, damageRequest.sourceEntityId)

  local knockbackFactor = (1 - status.stat("grit"))
  local momentum = knockbackMomentum(vec2.mul(damageRequest.knockbackMomentum, knockbackFactor))
  if status.resourcePositive("health") and vec2.mag(momentum) > 0 then
    self.applyKnockback = momentum
    if vec2.mag(momentum) > status.stat("knockbackThreshold") then
      status.setResource("stunned", math.max(status.resource("stunned"), status.stat("knockbackStunTime")))
    end
  end

  if not status.resourcePositive("health") then
    hitType = "kill"
  end
  return {{
    sourceEntityId = damageRequest.sourceEntityId,
    targetEntityId = entity.id(),
    position = mcontroller.position(),
    damageDealt = damage,
    healthLost = healthLost,
    hitType = hitType,
    kind = "Normal",
    damageSourceKind = damageRequest.damageSourceKind,
    targetMaterialKind = status.statusProperty("targetMaterialKind")
  }}
end

function knockbackMomentum(momentum)
  local knockback = vec2.mag(momentum)
  if mcontroller.baseParameters().gravityEnabled and math.abs(momentum[1]) > 0  then
    local dir = momentum[1] > 0 and 1 or -1
    return {dir * knockback / 1.41, knockback / 1.41}
  else
    return momentum
  end
end

function update(dt)
  if self.damageFlashTime > 0 then
    local color = status.statusProperty("damageFlashColor") or "ff0000=0.85"
    if self.damageFlashType == "strong" then
      color = status.statusProperty("strongDamageFlashColor") or "ffffff=1.0" or color
    elseif self.damageFlashType == "weak" then
      color = status.statusProperty("weakDamageFlashColor") or "000000=0.0" or color
    end
    status.setPrimaryDirectives(string.format("fade=%s", color))
  else
    status.setPrimaryDirectives()
  end
  self.damageFlashTime = math.max(0, self.damageFlashTime - dt)

  if self.applyKnockback then
    mcontroller.addMomentum(self.applyKnockback)
    self.applyKnockback = nil
  end

  if mcontroller.atWorldLimit(true) then
    status.setResourcePercentage("health", 0)
  end

  self.damageListener:update()
end
