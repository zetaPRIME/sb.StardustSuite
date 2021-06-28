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

dynAnim.parts.holding = {
  image = "/startech/objects/networkrelay2.png",
  bone = "frontHand",
  layer = {"Player",-100},
}
dynAnim.parts.holding2 = {
  image = "/startech/objects/networkrelay2.png",
  bone = "backHand",
  layer = {"Player-1",-100},
}

local state = 1
local lastFireMode
function update(dt, fireMode)
  
  local rot = mcontroller.rotation()
  
  local angle, dir = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
  activeItem.setFacingDirection(dir)
  --armature.bones.frontShoulder.rotation = (angle - rot*dir)--*dir
  --armature.bones.backShoulder.rotation = (angle - rot*dir)--*dir
  dynAnim.setArmAngles(angle - rot*dir, -angle - rot*dir)
  
  if fireMode ~= lastFireMode and fireMode == "primary" then
    --[[if state == 1 then
      dynAnim.setFrontArmState "in"
      dynAnim.setBackArmState "in"
      activeItem.setHoldingItem(true)
      state = 2
    elseif state == 2 then
      dynAnim.setFrontArmState "mid"
      dynAnim.setBackArmState "mid"
      state = 3
    else
      dynAnim.setFrontArmState "out"
      dynAnim.setBackArmState "out"
      activeItem.setHoldingItem(false)
      state = 1
    end]]
    --sb.logInfo("state change " .. state .. ", arm state " .. dynAnim.frontArmState())
    --mcontroller.setRotation(math.pi*4)
    local id = entity.id()
    sb.logInfo("id " .. id)
    --sb.logInfo("mouth dist: " .. vec2.mag(vec2.sub(world.entityPosition(id), world.entityMouthPosition(id))))
  end
  lastFireMode = fireMode
  
  dynAnim.update(dt)
end
