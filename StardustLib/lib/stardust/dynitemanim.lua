-- StardustLib.dynItemAnim - dynamic item animator

require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/lib/stardust/armature.lua"

-- TODO
-- directiveSets for cases like energyDirectives where you don't want to keep manually updating the asset every frame
-- draworder chunks? renderlayer and base zlevel for drawables to be relative to, so you can keep a weapon together
-- as it moves in front of and behind the player

do
  dynanim = { }
  
  local frontArmPivot = {0.375, 0.125}
  local backArmPivot = {-0.25, 0.125}
  
  -- set up default bones
  local boneArms = armature.newBone("arms", {position = {0, 0}, rotation = 0})
  local boneBackShoulder = armature.newBone("backShoulder", { parent = "arms", position = vec2.mul(backArmPivot, -1), rotation = 0 })
  local boneFrontShoulder = armature.newBone("frontShoulder", { parent = "arms", position = vec2.mul(frontArmPivot, -1), rotation = 0 })
  local boneBackArm = armature.newBone("backArm", { parent = "backShoulder", position = backArmPivot, rotation = 0 })
  local boneFrontArm = armature.newBone("frontArm", { parent = "frontShoulder", position = frontArmPivot, rotation = 0 })
  
  local boneFrontHand = armature.newBone("frontHand", { parent = "frontArm", position = {1.0, -0.125}, rotation = 0, mirrored = true})
  
  
  -- things to keep track of
  local setDir
  
  local didInit = false
  local frontArmImage
  local function initVis()
    didInit = true
    local backarm = world.entityPortrait(entity.id(), "full")[1].image
    backarm = string.gsub(backarm, ":(.-)%?", ":%%s?", 1)
    local frontarm = string.gsub(backarm, "back", "front", 1)
    sb.logInfo(frontarm, "%s")
    activeItem.setScriptedAnimationParameter("armBase", {back = backarm, front = frontarm})
    frontArmImage = string.format(frontarm, "rotation")
    
    -- both arms hidden with no log errors
    activeItem.setBackArmFrame("idle.1?multiply=0000")
    activeItem.setFrontArmFrame("idle.1?multiply=0000")
    
    activeItem.setScriptedAnimationParameter("entityId", entity.id())
    
    activeItem.setInstanceValue("animationScripts", {"/lib/stardust/render/dynitemanim.render.lua"})
    
    do -- hook activeitem functions
      local f = activeItem.setFacingDirection
      function activeItem.setFacingDirection(dir, ...)
        setDir = dir
        return f(dir, ...)
      end
    end
  end
  
  local pivotOffset
  do
    local curHp, lastHp = 0, 0
    local lastBw = false
    
    local pdir
    
    function updatePivot()
      local dir = setDir or mcontroller.facingDirection()
      setDir = nil
      if not pdir then pdir = dir end
      
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
      
      pivotOffset = vec2.add(hp, {-8/8 * pdir, 3.5/8})
      activeItem.setScriptedAnimationParameter("pivotOffset", pivotOffset)
      activeItem.setScriptedAnimationParameter("rotation", mcontroller.rotation())
      
      boneArms.position = pivotOffset
      boneArms.rotation = mcontroller.rotation() * dir
      boneArms.mirrored = dir < 0
      
      pdir = dir
    end
  end
  
  local test = 0
  function dynanim.update(dt)
    if not didInit then initVis() end
    
    if player then -- handle equipment sleeves
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
      
      local hide = false
      for _,s in pairs {"head", "chest", "legs"} do
        local itm = player.equippedItem(s.."Cosmetic") or player.equippedItem(s)
        if itm and root.itemConfig(itm).config.hideBody then hide = true break end
      end
      activeItem.setScriptedAnimationParameter("hideBase", hide)
    end
    
    updatePivot()
    
    test = test + dt
    boneFrontShoulder.rotation = math.sin(test*2.5) * math.pi * 0.25
    
    local a = { image = frontArmImage }
    local b = armature.bones.frontArm
    b:solve()
    a.position = b.solved.position
    a.rotation = b.solved.rotation
    a.mirrored = b.solved.mirrored
    
    local d = { image = "/items/generic/crafting/ironbar.png?multiply=ffffff7f" }
    local b = armature.bones.frontHand
    b:solve()
    d.position = b.solved.position
    d.rotation = b.solved.rotation
    d.mirrored = b.solved.mirrored
    activeItem.setScriptedAnimationParameter("drawableList", {a,d})
  end
end
