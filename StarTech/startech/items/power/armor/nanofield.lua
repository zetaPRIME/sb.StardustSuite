local modes = {
  ground = { },
  wing = { }
}
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
  soundActivate = "/sfx/objects/ancientlightplatform_on.ogg",
  soundDeactivate = "/sfx/objects/ancientlightplatform_off.ogg",
  soundThrust = "/sfx/npc/boss/kluexboss_vortex_windy.ogg",--"/sfx/objects/steel_elevator_loop.ogg",--"/sfx/tech/tech_sonicsphere_charge1.ogg",
  soundThrustVolume = 1,
  soundThrustBoostPitch = 1.22,
}

-- flags
local zeroG = false
local zeroGPrev = false

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

function init()
  --playerext.message("Nanofield online.")
  status.overConsumeResource("energy", 1.0) -- debug signal
  
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
  callMode("init", prev, prevState, ...)
end

function callMode(f, ...)
  if currentMode[f] then return currentMode[f](modeState, ...) end
end

local staticitm = "startech:nanofieldstatic"

local _prevKeys = { }
function update(p)
  if (playerext.getEquip("chest") or { }).name ~= "startech:nanofield" then
    return nil -- abort when no longer equipped
  end
  
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
  zeroG = world.gravity(mcontroller.position()) == 0
  
  --
  p.key = p.moves p.moves = nil
  p.key.sprint = not p.key.run
  p.keyPrev = _prevKeys
  _prevKeys = p.key
  p.keyDown = { }
  for k, v in pairs(p.key) do p.keyDown[k] = v and not p.keyPrev[k] end
  callMode("update", p)
  
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

-- movement modes!

local sqrt2 = math.sqrt(2)
local function vmag(vec)
  return math.sqrt(vec[1]^2 + vec[2]^2)
end

-----------------
-- ground mode --
-----------------

function modes.ground:init()
  tech.setParentState()
  mcontroller.setRotation(0)
  mcontroller.clearControls()
end

function modes.ground:update(p)
  --
  if p.keyDown["special1"] then
    setMode("wing", true)
  end
  if p.keyDown["shutup"] then
    local c = ""
    for k,v in pairs(p.key) do
      if v then c = c .. k .. ", " end
    end
    sb.logInfo("Moves: " .. c)
  end
  if p.key["sprint"] then -- sprint instead of slow walk!
    local v = 0
    if p.key["left"] then v = v - 1 end
    if p.key["right"] then v = v + 1 end
    if v ~= 0 then
      --mcontroller.controlApproachXVelocity(255 * v, 255)
      mcontroller.controlMove(v, true)
      mcontroller.controlModifiers({ speedModifier = 1.75 })
      --tech.setParentState("running")
    end
  end
  
  if zeroG and not zeroGPrev then setMode("wing") end
end

-----------------
-- elytra mode --
-----------------

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
end

function modes.wing:update(p)
  mcontroller.clearControls()
  mcontroller.controlParameters{
    --gravityMultiplier = 0.0001,
    gravityEnabled = false,
    normalGroundFriction = 0,
    ambulatingGroundFriction = 0,
    groundForce = 0, airForce = 0, liquidForce = 0, -- disable default movement entirely
  }
  mcontroller.controlDown()
  if p.keyDown.special1 then return setMode("ground") end
  
  local boost = 25
  local boostForce = 25*1.5
  
  local vx, vy = 0, 0  
  if p.key["up"] then vy = vy + 1 end
  if p.key["down"] then vy = vy - 1 end
  if p.key["left"] then vx = vx - 1 end
  if p.key["right"] then vx = vx + 1 end
  
  if vx ~= 0 and vy ~= 0 then
    vx = vx / sqrt2
    vy = vy / sqrt2
  elseif vx == 0 and vy == 0 then
    boostForce = boostForce * 1.2 -- greater braking force
  end
  
  -- don't drag across the ground
  if mcontroller.onGround() then
    --mcontroller.addMomentum({0, 3})
    --mcontroller.controlMove(vx, true)
  end
  
  if (vx ~= 0 or vy ~= 0) and p.key.sprint then
    boost = 55
    boostForce = boostForce * 1.5 + vmag(mcontroller.velocity()) * 2.5
  end
  
  mcontroller.controlApproachVelocity({vx*boost, vy*boost}, boostForce * 60 * p.dt)
  
  tech.setParentState("fly")
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
  rot2 = rot2 + self.vEff * 0.5
  
  -- sound
  self.thrustLoop:setVolume(wingStats.soundThrustVolume * util.clamp(vmag(mcontroller.velocity()) / 20, 0.0, 1.0))
  local pitch = vmag(mcontroller.velocity())
  if pitch <= 25 then
    pitch = util.lerp(util.clamp(pitch / 20, 0.0, 1.0), 0.25, 1.0)
  else
    pitch = util.lerp(util.clamp((pitch - 25) / (45-25), 0.0, 1.0), 1.0, wingStats.soundThrustBoostPitch)
  end
  self.thrustLoop:setPitch(pitch)
  
  -- handle props
  local offset = {-5 / 16, -15 / 16}
  wingFront:resetTransform()
  wingBack:resetTransform()
  
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
  --wingFront:scale({mcontroller.facingDirection(), 1.0}, {0.0, 0.0})
  --wingBack:scale({mcontroller.facingDirection(), 1.0}, {0.0, 0.0})
  
  if not zeroG and zeroGPrev then setMode("ground") end
end

function modes.wing:uninit()
  tech.setParentState()
  mcontroller.setRotation(0)
  mcontroller.clearControls()
  
  self.thrustLoop:discard()
  sound.play(wingStats.soundDeactivate)
end

function modes.wing:wingVisibility() return 1 end




















--
