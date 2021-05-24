-- StardustLib.dynItemAnim - dynamic item animator

require "/scripts/util.lua"
require "/scripts/vec2.lua"

do
  dynanim = { }
  
  local didInit = false
  local function initVis()
    didInit = true
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
    activeItem.setInstanceValue("animationScripts", {"/lib/stardust/render/dynitemanim.render.lua"})
  end
  
  local curHp, lastHp = 0, 0
  local lastBw = false
  function dynanim.update(dt)
    if not didInit then initVis() end
    
    if player then
      local ch = player.equippedItem("chestCosmetic") or player.equippedItem("chest")
      if ch then
        local cf = root.itemConfig(ch)
        local directives = cf.parameters.directives or cf.config.directives or ""
        local fr = cf.config[player.gender().."Frames"]
        if directives == "" and cf.config.colorOptions then
          -- TODO find a way to not need to recalculate this EVERY FUCKING FRAME
          local co = cf.config.colorOptions[1+(cf.parameters.colorIndex or 0)]
          directives = "?replace="
          for k,v in pairs(co) do
            directives = string.format("%s;%s=%s", directives, k, v)
          end
        end
        activeItem.setScriptedAnimationParameter("sleeve", {
          front = string.format("%s:%s%s", util.absolutePath(cf.directory, fr.frontSleeve), "%s", directives),
          back = string.format("%s:%s%s", util.absolutePath(cf.directory, fr.backSleeve), "%s", directives),
        })
      else
        activeItem.setScriptedAnimationParameter("sleeve", nil)
      end
    end
    
    local pDir = mcontroller.facingDirection()
    local angle, dir = activeItem.aimAngleAndDirection(0, activeItem.ownerAimPosition())
    activeItem.setFacingDirection(dir)
    
    animator.resetTransformationGroup("weapon")
    --animator.translateTransformationGroup("weapon", activeItem.handPosition {-8/8, 3.5/8})
    local vel = mcontroller.xVelocity()
    local offs = 1
    
    -- vars and flags
    local moving = mcontroller.walking() or mcontroller.running()
    local movingBack = moving and mcontroller.movingDirection() ~= dir
    if status.statPositive "stardustlib:customFlying" then movingBack = false end -- not back-moving when in elytra
    
    local bhp = -0.375
    local hp = activeItem.handPosition()
    
    -- keep track of changes in bob position, so we can...
    if hp[2] ~= curHp then
      lastHp = curHp
      curHp = hp[2]
    end
    
    -- compensate for wrong bobbing when moving backwards
    local bw = movingBack and not mcontroller.falling()
    if bw and not lastBw then curHp = bhp lastHp = bhp end
    lastBw = bw
    if bw then hp[2] = lastHp end
    
    -- fix backjump wonkiness
    if (not mcontroller.onGround()) and mcontroller.yVelocity() > -5 and movingBack then
      hp[2] = hp[2] + 0.125
    end
    if mcontroller.flying() then hp[2] = hp[2] + 2 end
    
    -- compensate for one frame delay on ducking, because starbound code is broken
    -- (bobbing still has the delay, but not as noticeable)
    if mcontroller.crouching() and mcontroller.canJump() then hp[2] = -1.375
    elseif hp[2] < -1 then hp[2] = bhp end
    
    activeItem.setScriptedAnimationParameter("handPos", vec2.add(hp, {-8/8 * pDir, 3.5/8}))
    activeItem.setScriptedAnimationParameter("rotation", mcontroller.rotation())
    local hide = false
    if player then
      for _,s in pairs {"head", "chest", "legs"} do
        local itm = player.equippedItem(s.."Cosmetic") or player.equippedItem(s)
        if itm and root.itemConfig(itm).config.hideBody then hide = true break end
      end
    end
    activeItem.setScriptedAnimationParameter("hideBase", hide)
  end
end
