require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/lib/stardust/dynitemanim.lua"

--[[
  extract backarm, frontarm from portrait
  replace frame and use for rendering
]]

function insit()
  local backarm = world.entityPortrait(entity.id(), "full")[1].image
  backarm = string.gsub(backarm, ":(.-)%?", ":%%s?", 1)
  local frontarm = string.gsub(backarm, "back", "front", 1)
  sb.logInfo(frontarm, "%s")
  activeItem.setScriptedAnimationParameter("armBase", {back = backarm, front = frontarm})
  
  -- both arms hidden with no log errors
  activeItem.setBackArmFrame("idle.1?multiply=0000")
  activeItem.setFrontArmFrame("idle.1?multiply=0000")
  
  activeItem.setScriptedAnimationParameter("entityId", entity.id())
  
  sb.logInfo("hp base "..activeItem.handPosition()[2])
  activeItem.setInstanceValue("animationScripts", {"warblades.render.lua"})
end

function update(dt, fireMode)
  
  dynanim.update(dt)
end
