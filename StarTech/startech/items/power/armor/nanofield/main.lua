--

require "/scripts/vec2.lua"
require "/lib/stardust/itemutil.lua"
require "/lib/stardust/tech/input.lua"

require "/startech/items/power/armor/nanofield/stats.lua"
require "/startech/items/power/armor/nanofield/movement.lua"

-- armor value works differently from normal armors
-- mult = .5^(armor/100); or, every 100 points is a 50% damage reduction

-- put this here for now
-- probably quadruple until module system is implemented
local tierBaseStats = {
  { -- T1 (Iron)
    armor = 5,
    health = 110,
    energy = 110,
    damageMult = 1.5,
  },
  { -- T2 (Tungsten) (default)
    armor = 10,
    health = 120,
    energy = 120,
    damageMult = 2.0,
  },
  { -- T3 (Titanium)
    armor = 30,
    health = 130,
    energy = 130,
    damageMult = 2.5,
  },
  { -- T4 (Durasteel)
    armor = 40,
    health = 140,
    energy = 140,
    damageMult = 3.0,
  },
  { -- T5 (Violium/Ferozium/Aegisalt)
    armor = 50,
    health = 150,
    energy = 150,
    damageMult = 3.5,
  },
  { -- T6 (Solarium)
    armor = 60,
    health = 160,
    energy = 160,
    damageMult = 4.0,
  },
}

local item
local itemModified = false
local statsNeedUpdate = true
local effectiveStatsNeedUpdate = false

local stats = {
  armor = 0,
  health = 100,
  energy = 100,
  damageMult = 1.0,
}

local modes = { }
local currentMode = { }
local modeState = { }

-- wing variables
local wingFront = Prop.new(2)
local wingBack = Prop.new(-2)
local wingVisibility = 0
local wingEffDir = 1.0

local wingStats
local wingDefaults = {
  energyColor = "ff0354",
  baseRotation = 0.0,
  soundActivate = "/sfx/objects/ancientlightplatform_on.ogg",
  soundDeactivate = "/sfx/objects/ancientlightplatform_off.ogg",
  soundThrust = "/sfx/npc/boss/kluexboss_vortex_windy.ogg",--"/sfx/objects/steel_elevator_loop.ogg",--"/sfx/tech/tech_sonicsphere_charge1.ogg",
  soundThrustVolume = 1.0,
  soundThrustPitch = 1.0,
  soundThrustBoostPitch = 1.22,
}
--[[ testing: Poptra
wingDefaults.baseRotation = 0.3
wingDefaults.soundThrust = "nyan.ogg"
wingDefaults.soundThrustVolume = 0.45
wingDefaults.soundThrustPitch = 0.9
wingDefaults.soundThrustBoostPitch = 1.0
--]]

-- flags
local zeroG = false
local zeroGPrev = false
local prevVelocity = {0, 0}

local function towards(cur, target, max)
  max = math.abs(max)
  if max == 0 then return cur end
  if target == cur then return target end
  local diff = target - cur
  local sign = diff / math.abs(diff)
  return cur + math.min(math.abs(diff), max) * sign
end

local function rotTowards(cur, target, max)
  --if (cur < 0) then cur = cur + math.pi * 2 end
  --if cur > math.pi then cur = cur - math.pi * 2 end
  --if (target < 0) then target = target + math.pi * 2 end
  --target = target - cur
  --while target > math.pi do target = target - math.pi * 2 end
  --while target < -math.pi do target = target + math.pi * 2 end
  --target = target + cur
  return towards(cur, target, max)
end

function drawEnergy(amount, testOnly)
  local res = playerext.drawEquipEnergy(amount, testOnly)
  if not testOnly then -- update cached item's capacitor
    item.parameters.batteryStats = playerext.getEquip("chest").parameters.batteryStats
  end
  return res
end

function modifyDamageTaken(msg, isLocal, damageRequest)
  if damageRequest.damageSourceKind == "falling" then
    if damageRequest.damage >= 50 then -- WIP: do something special on hard fall
      local vol = 1.0
      sound.play("/sfx/melee/hammer_hit_ground1.ogg", vol * 1.5, 1) -- impact low
      sound.play("/sfx/gun/grenadeblast_small_electric2.ogg", vol * 1.125, 0.75) -- impact mid
      sound.play("/sfx/objects/essencechest_open1.ogg", vol * 0.75, 1) -- impact high
      -- zoops
      --sound.play("/sfx/gun/erchiuseyebeam_start.ogg", vol * 1.5, 0.333)
      sound.play("/sfx/gun/erchiuseyebeam_start.ogg", vol * 1.0, 1)
      callMode("hardFall")
    else -- only a bit of a fall
      --playerext.message("dmg: " .. damageRequest.damage)
      local vol = 0.75
      sound.play("/sfx/melee/hammer_hit_ground1.ogg", vol * 1.15, 1) -- impact low
      sound.play("/sfx/gun/grenadeblast_small_electric2.ogg", vol * 0.5, 0.75) -- impact mid
      sound.play("/sfx/objects/essencechest_open1.ogg", vol * 0.75, 2) -- impact high
    end
    damageRequest.damageSourceKind = "applystatus" -- cancel fall damage
    return damageRequest
  elseif damageRequest.damageType == "Damage" then -- normal damage, apply DR
    damageRequest.damageType = "IgnoresDef"
    damageRequest.damage = damageRequest.damage * (.5 ^ (stats.armor / 100))
    return damageRequest
  end
end

function init()
  message.setHandler("stardustlib:modifyDamageTaken", modifyDamageTaken)
  message.setHandler("startech:nanofield.update", function() statsNeedUpdate = true end)
  --playerext.message("Nanofield online.")
  --status.overConsumeResource("energy", 1.0) -- debug signal
  
  message.setHandler("stardustlib:statusImbueQuery", function()
    world.sendEntityMessage(entity.id(), "stardustlib:statusImbueQueryReply", {
      '::{"tag":"antiSpace"}',
    })
  end)
  
  wingFront:scale({0, 0})
  wingBack:scale({0, 0})
  
  setMode("ground")
end

function setMode(mode, ...)
  if currentMode == modes[mode] or not modes[mode] then return nil end
  callMode("uninit", mode)
  local prev = currentMode
  local prevState = modeState
  currentMode = modes[mode]
  modeState = { }
  effectiveStatsNeedUpdate = true
  callMode("init", prev, prevState, ...)
end

function callMode(f, ...)
  if currentMode[f] then return currentMode[f](modeState, ...) end
end

local staticitm = "startech:nanofieldstatic"

local storedLevel

local _prevKeys = { }
function update(p)
  input.update(p)
  
  item = playerext.getEquip("chest") or { }
  itemModified = false
  if item.name ~= "startech:nanofield" then
    return nil -- abort when no longer equipped
  end
  local level = itemutil.property(item, "level") or 2
  if item.parameters.moduleSystem then -- carry over old leveling
    level = item.parameters.moduleSystem.tierCatalyst or level
    item.parameters.moduleSystem = nil
    item.parameters.level = level
    itemModified = true
    statsNeedUpdate = true
  end
  if storedLevel and storedLevel ~= level then statsNeedUpdate = true end -- update if upgraded
  storedLevel = level
  if statsNeedUpdate then updateStats() end
  
  -- maintain other slots
  for _, slot in pairs{"head", "legs"} do
    local itm = playerext.getEquip(slot) or { name = "manipulatormodule", count = 0 }
    if itm.name ~= staticitm .. slot then
      if (playerext.getEquip(slot .. "Cosmetic") or { }).count ~= 1 then
        playerext.setEquip(slot .. "Cosmetic", itm)
      else
        playerext.giveItems(itm)
      end
      playerext.setEquip(slot, { -- clear slot afterwards so that the slot isn't empty during giveItems
        name = staticitm .. slot,
        count = 1
      })
      -- clear out static if picked up
      if (playerext.getEquip("cursor") or { }).name == staticitm .. slot then playerext.setEquip("cursor", { name = "", count = 0 }) end
    end
  end
  
  zeroGPrev = zeroG
  zeroG = (world.gravity(mcontroller.position()) == 0) or status.statusProperty("fu_byosnogravity", false)
  
  if status.statusProperty("fu_byosnogravity", false) and not zeroGPrev then
    mcontroller.setVelocity(prevVelocity) -- override FU's BYOS system stopping you when it turns off gravity
  end
  --
  callMode("update", p)
  --movement.update(p)
  
  prevVelocity = mcontroller.velocity()
  
  -- update the item's property-stats
  if effectiveStatsNeedUpdate then updateEffectiveStats() end
  if itemModified then playerext.setEquip("chest", item) end
  
  -- handle wing directives
  local twv = callMode("wingVisibility") or 0
  if twv ~= wingVisibility then
    wingVisibility = towards(wingVisibility, twv, p.dt * 4)
    local ov = util.clamp(wingVisibility * 1.5, 0.0, 1.0)
    local fv = util.clamp(-.5 + wingVisibility * 1.5, 0.0, 1.0)
    local fade = ""
    fade = string.format("?multiply=FFFFFF%02x?fade=%s;%.3f", math.floor(0.5 + ov * 255), wingStats.energyColor or "ffffff", (1.0 - fv))
    wingFront:setDirectives(fade)
    wingBack:setDirectives(fade .. "?brightness=-40")
  end
  wingFront:scale({mcontroller.facingDirection() * wingEffDir, 1.0}, {0.0, 0.0})
  wingBack:scale({mcontroller.facingDirection() * wingEffDir, 1.0}, {0.0, 0.0})
  wingEffDir = mcontroller.facingDirection()
  
  --hud.update(p)
end

function uninit()
  callMode("uninit")
  
  -- destroy ephemera on unequip
  for _, slot in pairs{"head", "legs"} do
    local itm = playerext.getEquip(slot) or { }
    if itm.name == staticitm .. slot then
      playerext.setEquip(slot, { name = "", count = 0 }) -- clear item
    end
  end
end

function updateStats()
  local tierStats = tierBaseStats[itemutil.property(item, "level") or 2]--"/moduleSystem/tierCatalyst")]
  stats.armor = tierStats.armor * 4
  stats.health = tierStats.health
  stats.energy = tierStats.energy
  stats.damageMult = tierStats.damageMult
  
  statsNeedUpdate = false
  effectiveStatsNeedUpdate = true
end

function updateEffectiveStats()
  if item.parameters.statusEffects then
    item.parameters.statusEffects = nil
    itemModified = true
  end
  local sg = {
    { stat = "startech:wearingNanofield", amount = 1 },
    
    { stat = "breathProtection", amount = 1 },
    --{ stat = "nude", amount = -100 },
    
    { stat = "protection", amount = stats.armor },
    { stat = "maxHealth", amount = stats.health - 100 },
    { stat = "maxEnergy", amount = stats.energy - 100 },
    { stat = "powerMultiplier", baseMultiplier = stats.damageMult },
  }
  callMode("updateEffectiveStats", sg)
  tech.setStats(sg)
  
  effectiveStatsNeedUpdate = false
end

-- movement modes!

local sqrt2 = math.sqrt(2)
local function vmag(vec)
  return math.sqrt(vec[1]^2 + vec[2]^2)
end

-----------------
-- ground mode --
-----------------

modes.ground = { }
function modes.ground:init()
  tech.setParentState()
  mcontroller.setRotation(0)
  mcontroller.clearControls()
  
  self.airJumps = 0
end

function modes.ground:uninit()
  --
end

function modes.ground:update(p)
  --
  tech.setParentState() -- default to no state override
  
  if mcontroller.groundMovement() then self.airJumps = 1 end
  
  if input.keyDown.t1 then
    if input.key.down and not zeroG then
      setMode("sphere")
    else
      setMode("wing", true)
    end
  end
  if input.key.sprint then -- sprint instead of slow walk!
    local v = input.dir[1]
    if v ~= 0 then
      --mcontroller.controlApproachXVelocity(255 * v, 255)
      mcontroller.controlMove(v, true)
      mcontroller.controlModifiers({ speedModifier = 1.75 })
      --tech.setParentState("running")
    end
    if input.keyDown.jump and mcontroller.onGround() then -- slight bunnyhop effect
      mcontroller.setXVelocity(mcontroller.velocity()[1] * 1.5)
    end
  end
  
  -- air jump, borrowed from Aetheri
  if not mcontroller.canJump()
  and not mcontroller.jumping()
  and not mcontroller.liquidMovement()
  --and mcontroller.yVelocity() < 0
  and input.keyDown.jump and self.airJumps >= 1 then
    self.airJumps = self.airJumps - 1
    mcontroller.controlJump(true)
    mcontroller.setYVelocity(math.max(0, mcontroller.yVelocity()))
    mcontroller.controlParameters({ airForce = 1750.0 }) -- allow easier direction control during jump
    sound.play("/sfx/tech/tech_doublejump.ogg")
    tech.setParentState("Fall") -- animate a bit even when already rising
  end
  
  if zeroG and not zeroGPrev then setMode("wing") end
end

function modes.ground:hardFall()
  setMode("hardFall")
end

-- fall recovery
modes.hardFall = { }
function modes.hardFall:init()
  self.time = 0
  self.startingVelocity = prevVelocity[1]
end

function modes.hardFall:uninit()
  mcontroller.clearControls()
  tech.setParentState()
end

function modes.hardFall:update(p)
  mcontroller.controlModifiers({ speedModifier = 0, normalGroundFriction = 0, ambulatingGroundFriction = 0 }) -- just a tiny bit of slide
  mcontroller.setXVelocity(prevVelocity[1] * (1.0 - 5.0 * p.dt))
  tech.setParentState("duck")
  self.time = self.time + p.dt
  if self.time >= 0.333 or not mcontroller.onGround() then
    setMode("ground")
  elseif input.keyDown.jump then
    mcontroller.controlJump(5)
    mcontroller.setVelocity({self.startingVelocity * 2.5, -5})
  end
end

-----------------
-- sphere mode --
-----------------

modes.sphere = { }
function modes.sphere:init()
  self.collisionPoly = { {-0.85, -0.45}, {-0.45, -0.85}, {0.45, -0.85}, {0.85, -0.45}, {0.85, 0.45}, {0.45, 0.85}, {-0.45, 0.85}, {-0.85, 0.45} }
  mcontroller.controlParameters({ collisionPoly = self.collisionPoly })
  mcontroller.setYPosition(mcontroller.position()[2]-(29/16))
  
  tech.setToolUsageSuppressed(true)
  tech.setParentHidden(true)
  self.ball = Prop.new(0)
  self.ball:setImage("/tech/distortionsphere/distortionsphere.png", "/tech/distortionsphere/distortionsphereglow.png")
  self.ball:setFrame(0)
  self.rot = 0.5
  sound.play("/sfx/tech/tech_sphere_transform.ogg")
end

function modes.sphere:uninit()
  self.ball:discard()
  tech.setParentHidden(false)
  tech.setToolUsageSuppressed(false)
  sound.play("/sfx/tech/tech_sphere_transform.ogg")
  mcontroller.setYPosition(mcontroller.position()[2]+(29/16))
  mcontroller.clearControls()
end

function modes.sphere:update(p)
  if input.keyDown.t1 then -- unmorph
    return setMode(zeroG and "wing" or "ground")
  end
  mcontroller.clearControls()
  mcontroller.controlParameters({
    collisionPoly = self.collisionPoly,
    groundForce = 450,
    runSpeed = 25, walkSpeed = 25,
    normalGroundFriction = 0.75,
    ambulatingGroundFriction = 0.2,
    slopeSlidingFactor = 3.0,
  })
  self.rot = self.rot + mcontroller.xVelocity() * p.dt * -2.0
  while self.rot < 0 do self.rot = self.rot + 8 end
  while self.rot >= 8 do self.rot = self.rot - 8 end
  self.ball:setFrame(math.floor(self.rot))
end

function modes.sphere:hardFall()
  mcontroller.setXVelocity(prevVelocity[1] * 2)
end

-----------------
-- elytra mode --
-----------------

modes.wing = { }
function modes.wing:init(_, _, summoned)
  self.hEff = 0
  self.vEff = 0
  
  wingStats = wingDefaults
  
  if summoned then
    self.summoned = true
    if mcontroller.onGround() then -- lift off ground a bit
      mcontroller.controlApproachYVelocity(12, 65536)
    end
  end
  
  wingFront:setImage("elytra.png")
  wingBack:setImage("elytra.png")
  --wingBack:setDirectives("?brightness=-40")
  sound.play(wingStats.soundActivate)
  self.thrustLoop = sound.newLoop(wingStats.soundThrust)
  
  -- temporarily kill problematic FR effects
  status.removeEphemeralEffect("swimboost2")
end

function modes.wing:uninit()
  tech.setParentState()
  mcontroller.setRotation(0)
  mcontroller.clearControls()
  
  self.thrustLoop:discard()
  sound.play(wingStats.soundDeactivate)
  
  -- restore FR effects
  world.sendEntityMessage(entity.id(), "playerext:reinstateFRStatus")
end

function modes.wing:updateEffectiveStats(sg)
  util.appendLists(sg, {
    -- glide effortlessly through most FU gases
    { stat = "gasImmunity", amount = 1.0 },
    { stat = "helium3Immunity", amount = 1.0 },
  })
end

-- couple functions from Aetheri
local elytraSetPose = coroutine.wrap(function()
  local threshold = 1/6
  local t = 0.0
  local f = false
  while true do
    local a = ((vec2.mag(input.dirN) ~= 0 and vec2.dot(input.dirN, vec2.norm(mcontroller.velocity())) > 0) and 1.0 or -1.0) * script.updateDt()
    t = util.clamp(t + a/threshold, 0.0, 1.0)
    if t == 1.0 then f = true elseif t == 0.0 then f = false end
    if f then tech.setParentState("fly") else tech.setParentState() end
    coroutine.yield()
  end
end)

local function forceFacing(f)
  mcontroller.controlModifiers{movementSuppressed = false}
  mcontroller.controlFace(f)
  mcontroller.controlModifiers{movementSuppressed = true}
end

function modes.wing:update(p)
  mcontroller.clearControls()
  mcontroller.controlParameters{
    gravityEnabled = false,
    frictionEnabled = false,
    liquidImpedance = -100, -- full speed in water
    liquidBuoyancy = -1000, -- same as above
    groundForce = 0, airForce = 0, liquidForce = 0, -- disable default movement entirely
    maximumPlatformCorrection = 0.0,
    maximumPlatformCorrectionVelocityFactor = 0.0,
  }
  mcontroller.controlModifiers{ movementSuppressed = true } -- disable harder, and also don't paddle at the air
  if input.keyDown.t1 then return setMode("ground") end
  
  local curSpeed = vec2.mag(mcontroller.velocity())
  
  local boost = input.key.sprint and 55 or 25
  
  if input.dir[1] ~= 0 then forceFacing(input.dir[1]) end
  
  -- for now this is just taken straight from the Aetheri
  local forceMult = util.lerp((1.0 - vec2.dot(input.dirN, vec2.norm(mcontroller.velocity()))) * 0.5, 0.5, 1.0)
  if vec2.mag(input.dirN) < 0.25 then forceMult = 0.25 end
  mcontroller.controlApproachVelocity(vec2.mul(input.dirN, boost), 12500 * forceMult * p.dt)
  
  elytraSetPose()
  self.hEff = towards(self.hEff, util.clamp(mcontroller.velocity()[1] / 55, -1.0, 1.0), p.dt * 8)
  self.vEff = towards(self.vEff, util.clamp(mcontroller.velocity()[2] / 55, -1.0, 1.0), p.dt * 8)
  --local rot = util.clamp(mcontroller.velocity()[1] / -55, -1.0, 1.0)
  local rot = math.sin(self.hEff * -1 * math.pi * .45) / (.45*2)
  local targetRot = rot * math.pi * .09
  mcontroller.setRotation(rotTowards(mcontroller.rotation(), targetRot, math.pi * .09 * 8 * p.dt))
  
  local rot2 = self.hEff * -1 * mcontroller.facingDirection()
  if rot2 < 0 then -- less extra rotation when moving forwards
    rot2 = rot2 * 0.32
  else -- and a wing flare
    rot2 = rot2 * 1.7
  end
  rot2 = rot2 + self.vEff * 0.75
  
  -- sound
  self.thrustLoop:setVolume(wingStats.soundThrustVolume * util.clamp(vmag(mcontroller.velocity()) / 20, 0.0, 1.0))
  local pitch = vmag(mcontroller.velocity())
  if pitch <= 25 then
    pitch = util.lerp(util.clamp(pitch / 20, 0.0, wingStats.soundThrustPitch), 0.25, 1.0)
  else
    pitch = util.lerp(util.clamp((pitch - 25) / (45-25), 0.0, 1.0), wingStats.soundThrustPitch, wingStats.soundThrustBoostPitch)
  end
  self.thrustLoop:setPitch(pitch)
  
  -- handle props
  local offset = {-5 / 16, -15 / 16}
  wingFront:resetTransform()
  wingBack:resetTransform()
  
  -- base rotation first
  wingFront:rotate(wingStats.baseRotation)
  wingBack:rotate(wingStats.baseRotation)
  
  -- rotate wings relative to attachment
  wingFront:rotate(rot2 * math.pi * .14)
  wingBack:rotate(rot2 * math.pi * .07)
  wingBack:rotate(-0.11)
  
  -- then handle attachment sync
  wingFront:translate(offset)
  wingFront:rotate(mcontroller.rotation() * mcontroller.facingDirection())
  wingBack:translate(offset)
  wingBack:translate({3 / 16, 0 / 16})
  wingBack:rotate(mcontroller.rotation() * mcontroller.facingDirection())
  wingEffDir = 1.0
  
  if not zeroG and zeroGPrev then setMode("ground") end
end

function modes.wing:wingVisibility() return 1 end




















--
