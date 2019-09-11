--

function init()
  if world.entityType(entity.id()) ~= "player" then
    local amt = effect.duration()
    local eff = status.getPersistentEffects("stardustlib:armorstrip")
    local mult = 1.0
    if eff and eff[1] then mult = eff[1].effectiveMultiplier or mult end
    --sb.logInfo("amt " .. amt .. " mult " .. mult)
    status.setPersistentEffects("stardustlib:armorstrip", {
      { stat = "protection", effectiveMultiplier = math.max(0, mult - amt) }
    })
  end
  effect.expire()
end
