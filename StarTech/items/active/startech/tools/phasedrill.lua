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
- unique graphics instead of it being a clone of the doom cannon
- visually distinguish beam modes
- make beam not fire backwards (and always fire forwards the minimum amount)
- flashlight effect when turned off
- make beam end look like it's actually doing something (particles)
- "charge ring" drawing inwards at the beam focus while charging up
- deal damage over time to hostiles in the beam's path
  - push erchius ghost?
- additional sound layers for damaging tiles and entities

- configurable strength and radius values?

- proper power draw logic and configuration... once a fluxpack exists

- make it only spawn the item collector stagehand if there's items there
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
  --sf = sf .. "?scalebilinear=1.0=" .. util.round(width or 1.0, 3)
  sf = sf .. string.format("?multiply=FFFFFF%x", util.round(opacity * 255, 0))
  
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

states.idle = {
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
  end,
  exit = function()
    --animator.stopAllSounds("fireloop")
    animator.setSoundVolume("fireloop", 0, 0.125)
  end,
  update = function(dt, fireMode, shiftHeld)
    if power.drawEquipEnergy(20) < 20 then
      enterState("release")
      return nil
    end
    
    local owner = activeItem.ownerEntityId()
    local origin = vec2.add(mcontroller.position(), activeItem.handPosition(self.weapon.muzzleOffset))
    local endpoint = activeItem.ownerAimPosition()
    
    local pt = world.lineCollision(origin, endpoint) or endpoint
    
    local burst = 1 - math.min(state.time * 4.0, 1)
    burst = burst * burst
    setBeam(pt, 1.0 + burst * 0.5, 1.0)
    
    if fireMode ~= "none" then
      local rad = 4
      
      if shiftHeld then
        -- todo: actually collect liquids
        for y = -1, 1 do
          for x = -1, 1 do
            world.destroyLiquid({pt[1] + x, pt[2] + y})
          end
        end
        world.spawnStagehand(pt, "stardustlib:itemcollector", { radius = rad * 1.25 * 1.25, target = owner })
      elseif fireMode == "primary" then
        world.damageTileArea(pt, rad, "foreground", origin, "beamish", 1, 99999)
        world.spawnStagehand(pt, "stardustlib:itemcollector", { radius = rad * 1.25, target = owner })
        --[[for k,id in pairs(world.itemDropQuery(pt, rad)) do
          local itm = world.takeItemDrop(id, owner);
          if player and itm then player.giveItem(itm) end
        end]]
      else
        world.damageTileArea(pt, rad * 0.64, "foreground", origin, "beamish", 1, 99999)
        world.damageTileArea(pt, rad * 0.64, "background", origin, "beamish", 1, 99999)
        world.spawnStagehand(pt, "stardustlib:itemcollector", { radius = rad * 0.64 * 1.25, target = owner })
        --[[for k,id in pairs(world.itemDropQuery(pt, rad * 0.64)) do
          local itm = world.takeItemDrop(id, owner);
          if player and itm then player.giveItem(itm) end
        end]]
      end
    else enterState("release") end
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
    if state.time >= duration then enterState("idle") end
  end
}










-- eof
