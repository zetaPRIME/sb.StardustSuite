require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/weapon.lua"

require "/lib/stardust/power.item.lua"

state = {} -- state data
states = {} -- list of state machines
currentState = ""
function stateUpdate(dt, ...)
  state.time = (state.time or 0) + dt
  state.tick = (state.tick or 0) + 1
  local s = states[currentState] or {}
  if s.update then s.update(dt, ...) end
end
function enterState(stateName, ...)
  local s = states[currentState] or {}
  if s.exit then s.exit() end
  currentState = stateName;
  state = {time = 0, tick = 0}
  s = states[currentState] or {}
  if s.enter then s.enter(...) end
end

--[[
TODO:
- visually distinguish beam modes (more)
- make beam not fire backwards (and always fire forwards the minimum amount)
- make beam end look like it's actually doing something (particles)
- "charge ring" drawing inwards at the beam focus while charging up
- push erchius ghost?
- additional sound layers for damaging tiles and entities
- fix single-digit hex derp for transparency (FFFFFF... 0)
]]

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)
  self.weapon:init()
  
  self.weapon:setStance({
    armRotation = 0,
    weaponRotation = 0,
    twoHanded = true,
    allowRotate = true,
    allowFlip = true
  })
  
  self.chain = config.getParameter("chain", {})
  
  cfg = config.getParameter("beamStats")
  pwr = config.getParameter("powerUsage")
  
  enterState("idle")
end

function uninit()
  enterState("")
  self.weapon:uninit()
end

lastFireMode = nil
function update(dt, fireMode, shiftHeld)
  if not lastFireMode then lastFireMode = fireMode end
  self.weapon:update(dt, fireMode, shiftHeld)
  stateUpdate(dt, fireMode, shiftHeld)
  lastFireMode = fireMode
end

function killBeam()
  activeItem.setScriptedAnimationParameter("chains", nil)
end

function setBeam(endPoint, width, opacity)
  local chain = copy(self.chain)
  chain.startOffset = self.weapon.muzzleOffset
  chain.endPosition = endPoint
  
  local sf = ""
  sf = string.format("%s?multiply=FFFFFF%x", sf, util.round(opacity * 255, 0))
  
  chain.startSegmentImage = chain.startSegmentImage .. sf
  chain.segmentImage = chain.segmentImage .. sf
  chain.endSegmentImage = chain.endSegmentImage .. sf
  
  chain.baseScale = chain.baseScale or {1.0, 1.0}
  if type(chain.baseScale) ~= "table" then chain.baseScale = {chain.baseScale, chain.baseScale} end
  chain.baseScale[2] = chain.baseScale[2] * width
  
  if chain.segmentLight then 
    local l = chain.segmentLight.color
    l[1] = l[1] * opacity * 0.64;
    l[2] = l[2] * opacity * 0.64;
    l[3] = l[3] * opacity * 0.64;
  end
  

  activeItem.setScriptedAnimationParameter("chains", {chain})
end

function collectItems(pt, radius)
  if world.itemDropQuery(pt, radius)[1] then -- only spawn stagehand if items are present in range, lest allocation lag occur for no reason
    world.spawnStagehand(pt, "stardustlib:itemcollector", { radius = radius, target = activeItem.ownerEntityId() })
  end
end

function damageEntities(p1, p2, dmg)
  local owner = activeItem.ownerEntityId()
  local numHit = 0
  for k,id in pairs(world.entityLineQuery(p1, p2, { includedTypes = { "creature" } })) do
    if world.entityCanDamage(owner, id) then
      numHit = numHit + 1
      -- okay, guess this is the only way to actually "directly" damage an entity...
      -- TODO: put this in a library
      world.spawnProjectile("invisibleprojectile", world.entityPosition(id), owner, {0,0}, false, { power = dmg, damageKind = "plasma", timeToLive = 0.001 })
    end
  end
  return numHit
end

states.idle = {
  enter = function()
    activeItem.setCursor("/cursors/reticle5.cursor")
    animator.setLightActive("flashlight", true)
  end,
  exit = function()
    animator.setLightActive("flashlight", false)
  end,
  update = function(dt, fireMode, shiftHeld)
    killBeam()
    
    if fireMode ~= lastFireMode and fireMode ~= "none" then
      enterState("charge")
    end
  end
}

states.charge = {
  enter = function()
    animator.stopAllSounds("charge")
    animator.playSound("charge")
    animator.setSoundVolume("charge", 1, 0)
  end,
  exit = function()
    animator.setSoundVolume("charge", 0, 0.1)
  end,
  update = function(dt, fireMode, shiftHeld)
    local owner = activeItem.ownerEntityId()
    local origin = vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
    local endpoint = activeItem.ownerAimPosition()
    
    local pt = world.lineCollision(origin, endpoint) or endpoint
    
    local bw = 1.0 / math.min(state.time * 8.0, 1)
    bw = (1.0 / (bw * bw)) * 0.25
    local op = 0.25 + state.time
    setBeam(pt, bw, op)
    activeItem.setCursor(string.format("/cursors/reticle%i.cursor", math.max(0, math.ceil(5 - (state.time * 10)))))
    
    if fireMode == "none" then enterState("idle") 
    elseif state.time >= 0.5 then enterState("fire")
    end
  end
}

states.fire = {
  enter = function()
    animator.playSound("firestart")
    animator.stopAllSounds("fireloop")
    animator.playSound("fireloop", -1)
    animator.setSoundVolume("fireloop", 1, 0)
    --animator.setSoundPitch("fireloop", 1.5, 0)
    activeItem.setCursor("/cursors/reticle0.cursor")
  end,
  exit = function()
    --animator.stopAllSounds("fireloop")
    animator.setSoundVolume("fireloop", 0, 0.125)
  end,
  update = function(dt, fireMode, shiftHeld)
    local owner = activeItem.ownerEntityId()
    local origin = vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
    local endpoint = activeItem.ownerAimPosition()
    
    local pt = world.lineCollision(origin, endpoint) or endpoint
    
    local burst = 1 - math.min(state.time * 4.0, 1)
    burst = burst * burst
    local bw = 1.0 + burst * 0.5
    
    local aec = 0
    
    if fireMode ~= "none" and power.drawEquipEnergy(pwr.base) >= pwr.base then
      local str = cfg.tileStrength
      local rad = cfg.baseRadius
      local dmg = cfg.entityDamage
      
      if shiftHeld then
        -- todo: actually collect liquids
        for y = -1, 1 do
          for x = -1, 1 do
            world.destroyLiquid({pt[1] + x, pt[2] + y})
          end
        end
        bw = bw * 0.8
        collectItems(pt, rad * 1.25 * 1.25)
      elseif fireMode == "primary" then
        if world.damageTileArea(pt, rad, "foreground", origin, "beamish", 1, 99999) then aec = aec + pwr.hitTilesPrimary end
        aec = aec + damageEntities(origin, pt, dmg) * pwr.hitEnemy
        collectItems(pt, rad * 1.25)
      else
        if world.damageTileArea(pt, rad * 0.64, "foreground", origin, "beamish", 1, 99999) then aec = aec + pwr.hitTilesSecondary end
        if world.damageTileArea(pt, rad * 0.64, "background", origin, "beamish", 1, 99999) then aec = aec + pwr.hitTilesSecondary end
        aec = aec + damageEntities(origin, pt, dmg) * pwr.hitEnemy
        collectItems(pt, rad * 0.64 * 1.25)
      end
    else enterState("release") end
    
    setBeam(pt, bw, 1.0)
    if aec > 0 then
      power.drawEquipEnergy(aec)
    end
  end
}

states.release = {
  update = function(dt, fireMode, shiftHeld)
    local duration = 0.125
    
    local owner = activeItem.ownerEntityId()
    local origin = vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
    local endpoint = activeItem.ownerAimPosition()
    
    local pt = world.lineCollision(origin, endpoint) or endpoint
    
    local fade = math.min(state.time / duration, 1)
    fade = 1 - (fade * fade)
    setBeam(pt, fade, fade)
    activeItem.setCursor(string.format("/cursors/reticle%i.cursor", math.max(0, math.ceil(state.time * 5 / duration))))
    
    if state.time >= duration then enterState("idle") end
  end
}










-- eof
