-- StardustLib.dynItemAnim - dynamic item animator

require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/lib/stardust/armature.lua"

-- TODO
-- directiveSets for cases like energyDirectives where you don't want to keep manually updating the asset every frame
-- draworder chunks? renderlayer and base zlevel for drawables to be relative to, so you can keep a weapon together
-- as it moves in front of and behind the player

do
  dynAnim = { }
  dynAnim.parts = { }
  dynAnim.effects = { }
  dynAnim.bones = armature.bones -- alias this here
  
  local frontArmPivot = {0.375, 0.125}
  local backArmPivot = {-0.25, 0.125}
  
  -- set up default bones
  local boneCharacter = armature.newBone("character", { position = {0, 0}, rotation = 0 })
  local boneArms = armature.newBone("arms", { parent = "character", position = {0, 0}, rotation = 0 })
  local boneBackShoulder = armature.newBone("backShoulder", { parent = "arms", position = vec2.mul(backArmPivot, -1), rotation = 0 })
  local boneFrontShoulder = armature.newBone("frontShoulder", { parent = "arms", position = vec2.mul(frontArmPivot, -1), rotation = 0 })
  local boneBackArm = armature.newBone("backArm", { parent = "backShoulder", position = {0, 0}, rotation = 0 })
  local boneBackArmVis = armature.newBone("backArmVis", { parent = "backArm", position = backArmPivot, rotation = 0 })
  local boneFrontArm = armature.newBone("frontArm", { parent = "frontShoulder", position = {0, 0}, rotation = 0 })
  local boneFrontArmVis = armature.newBone("frontArmVis", { parent = "frontArm", position = frontArmPivot, rotation = 0 })
  
  local boneBackHand = armature.newBone("backHand", { parent = "backShoulder", rotation = 0 })
  local boneFrontHand = armature.newBone("frontHand", { parent = "frontShoulder", rotation = 0 })
  
  local paramBack = { } local paramFront = { }
  
  -- and default parts
  local parts = dynAnim.parts
  parts.backArm = { bone = "backArmVis", layer = {"Player-1", 0}, imageParams = paramBack }
  parts.backSleeve = { bone = "backArmVis", layer = {"Player-1", 1}, imageParams = paramBack }
  parts.frontArm = { bone = "frontArmVis", layer = {"Player", 0}, imageParams = paramFront }
  parts.frontSleeve = { bone = "frontArmVis", layer = {"Player", 1}, imageParams = paramFront }
  
  local armStates = { }
  local function armState(p)
    if not p.id then return end
    local s = { }
    armStates[p.id] = s
    
    s.frontFrame = p.frontFrame or p.frame
    s.backFrame = p.backFrame or p.frame
    s.frontPos = p.frontPos or p.pos
    s.backPos = p.backPos or p.pos
    s.frontRot = p.frontRot or p.rot or 0
    s.backRot = p.backRot or p.rot or 0
    s.backOffset = p.backOffset or backArmPivot
    s.frontOffset = p.frontOffset or frontArmPivot
  end
  dynAnim.customArmState = armState
  
  armState { id = "out",
    frame = "rotation",
    pos = {9.5/8, -2.5/8},
  }
  armState { id = "mid",
    backFrame = "jump.3", frontFrame = "run.1",
    pos = {5.5/8, -2.0/8},
    backOffset = {-0.25, 0.125}, backRot = math.pi * -1/16,
    frontOffset = {0.125, 0.0}, frontRot = math.pi * -1/16,
  }
  armState { id = "in",
    backFrame = "swim.1", frontFrame = "swimIdle.1",
    pos = {2.5/8, -3.5/8},
    backOffset = {-0.625, -0.125}, --backRot = math.pi * -4/16,
    frontOffset = {0.375, -0.125},
  }
  
  local backArmState
  local frontArmState
  function dynAnim.backArmState() return backArmState end
  function dynAnim.frontArmState() return frontArmState end
  function dynAnim.setBackArmState(id)
    local s = armStates[id or false]
    if not s then return end
    backArmState = id
    paramBack[1] = s.backFrame
    boneBackHand.position = s.backPos
    boneBackArm.rotation = s.backRot
    boneBackArmVis.position = s.backOffset
  end
  function dynAnim.setFrontArmState(id)
    local s = armStates[id or false]
    if not s then return end
    frontArmState = id
    paramFront[1] = s.frontFrame
    boneFrontHand.position = s.frontPos
    boneFrontArm.rotation = s.frontRot
    boneFrontArmVis.position = s.frontOffset
  end
  function dynAnim.setArmStates(front, back)
    dynAnim.setFrontArmState(front)
    dynAnim.setBackArmState(back or front)
  end
  
  dynAnim.setArmStates("out", "out")
  
  function dynAnim.setBackArmAngle(a)
    boneBackShoulder.rotation = a
  end
  function dynAnim.setFrontArmAngle(a)
    boneFrontShoulder.rotation = a
  end
  function dynAnim.setArmAngles(front, back)
    boneFrontShoulder.rotation = front
    boneBackShoulder.rotation = back or front
  end
  
  
  -- things to keep track of
  local setDir
  local setRotation
  local holdingItem
  
  local didInit = false
  local function initVis()
    didInit = true
    local backarm = world.entityPortrait(entity.id(), "full")[1].image
    backarm = string.gsub(backarm, ":(.-)%?", ":%%s?", 1)
    local frontarm = string.gsub(backarm, "back", "front", 1)
    
    parts.backArm.image = backarm
    parts.frontArm.image = frontarm
    
    -- both arms hidden with no log errors
    activeItem.setBackArmFrame("idle.1?multiply=0000")
    activeItem.setFrontArmFrame("idle.1?multiply=0000")
    
    activeItem.setScriptedAnimationParameter("entityId", entity.id())
    
    activeItem.setInstanceValue("animationScripts", {"/lib/stardust/render/dynitemanim.render.lua"})
    
    do -- hook activeitem etc. functions
      local f = activeItem.setFacingDirection
      function activeItem.setFacingDirection(dir, ...)
        setDir = dir
        return f(dir, ...)
      end
      local f = mcontroller.setRotation
      function mcontroller.setRotation(r, ...)
        setRotation = r
        return f(r, ...)
      end
      local f = activeItem.setHoldingItem
      function activeItem.setHoldingItem(b, ...)
        holdingItem = b and 0
        return f(b, ...)
      end
      activeItem.setHoldingItem(true)
    end
  end
  
  local pivotOffset
  do
    local curHp, lastHp = 0, 0
    local lastBw = false
    
    local pdir
    
    local hp
    
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
      if not hp or holdingItem == true then hp = activeItem.handPosition() end
      
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
      if (mcontroller.crouching() and mcontroller.canJump()) or status.statPositive "stardustlib:forcedCrouch" then hp[2] = -1.375
      elseif hp[2] < -1 then hp[2] = bhp end
      
      pivotOffset = vec2.add(hp, {-8/8 * pdir, 3.5/8})
      --activeItem.setScriptedAnimationParameter("pivotOffset", pivotOffset)
      --activeItem.setScriptedAnimationParameter("rotation", mcontroller.rotation())
      
      boneArms.position = pivotOffset
      boneCharacter.mirrored = dir < 0
      boneCharacter.rotation = (setRotation or mcontroller.rotation()) --* dir
      
      setRotation = nil -- clear
      pdir = dir
    end
  end
  
  local test = 0
  function dynAnim.update(dt)
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
        parts.backSleeve.image = string.format("%s:%s%s", util.absolutePath(cf.directory, fr.backSleeve), "%s", directives)
        parts.frontSleeve.image = string.format("%s:%s%s", util.absolutePath(cf.directory, fr.frontSleeve), "%s", directives)
      else
        parts.backSleeve.image = nil
        parts.frontSleeve.image = nil
      end
      
      local hide = false
      for _,s in pairs {"head", "chest", "legs"} do
        local itm = player.equippedItem(s.."Cosmetic") or player.equippedItem(s)
        if itm and root.itemConfig(itm).config.hideBody then hide = true break end
      end
      parts.frontArm.hide = hide
      parts.backArm.hide = hide
    end
    
    if holdingItem then updatePivot() end
    
    local dl = { }
    if holdingItem then -- render armatured parts only when held
      for k, p in pairs(dynAnim.parts) do
        if p.image and not p.hide then -- only visible
          local b = armature.bones[p.bone or false]
          if b then
            local d = { }
            dl[k] = d
            
            -- set status from bone
            b:solve()
            d.position = b.solved.position
            d.rotation = b.solved.rotation
            d.mirrored = b.solved.mirrored
            
            d.fullbright = p.fullbright
            d.scale = p.scale
            
            
            if p.imageParams then
              d.image = string.format(p.image, table.unpack(p.imageParams))
            else d.image = p.image end
            
            if type(p.layer) == "table" then
              d.layer = p.layer[1]
              d.z = (p.z or 0) + (p.layer[2] or 0)
            else
              d.layer = p.player
              d.z = p.z
            end
          end
        end
      end
      --
    end
    for k, p in pairs(dynAnim.effects) do -- always render effect images
      if p.image and not p.hide then -- only visible
        local d = { }
        dl["_eff_" .. k] = d
        
        d.position = p.position or {0, 0}
        d.rotation = p.rotation or 0
        d.mirrored = p.mirrored
        
        d.fullbright = p.fullbright
        d.scale = p.scale
        
        if p.imageParams then
          d.image = string.format(p.image, table.unpack(p.imageParams))
        else d.image = p.image end
        
        if type(p.layer) == "table" then
          d.layer = p.layer[1]
          d.z = (p.z or 0) + (p.layer[2] or 0)
        else
          d.layer = p.player
          d.z = p.z
        end
      end
    end
    if holdingItem == 0 then holdingItem = true end
    
    activeItem.setScriptedAnimationParameter("drawableList", dl)
  end
end
