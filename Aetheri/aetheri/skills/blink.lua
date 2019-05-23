--

require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"

require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"

-- TODO: sfx and maybe visuals in a mp-visible way

local burstReplace = {"fefffe", "d8d2ff", "b79bff", "8e71da"}
local directives = ""

function updateColors()
  -- recolor to match user's core palette
  local appearance = status.statusProperty("aetheri:appearance", { })
  if appearance.palette then
    directives = color.replaceDirective(burstReplace, appearance.palette)
    --lightColor = appearance.glowColor or appearance.palette[2]
  end
end

local cooldown = 0
local cooldownTime = 0.25

function init()
  activeItem.setHoldingItem(false)
  activeItem.setTwoHandedGrip(false)
  
  updateColors()
  message.setHandler("aetheri:paletteChanged", updateColors)
end

local anim
local animTime = 0.125

local rangeFull = 2*25
local rangeSmall = 2*7.5

local lastFireMode
local buffered
function update(dt, fireMode, shiftHeld)
  if fireMode == lastFireMode then fireMode = nil else lastFireMode = fireMode end
  local aimPos = vec2.add(activeItem.ownerAimPosition(), vec2.mul(mcontroller.velocity(), dt))
  local angle, dir = activeItem.aimAngleAndDirection(0, aimPos)
  activeItem.setFacingDirection(dir)
  
  local aimVec = vec2.mul(vec2.rotate({1, 0}, angle), {dir, 1})
  
  cooldown = math.max(cooldown - dt / cooldownTime, 0)
  if cooldown <= 0.75 and fireMode ~= "none" then buffered = fireMode end
  if cooldown == 0 and buffered then
    local costMult = 0.7
    local range = buffered == "primary" and rangeFull or rangeSmall
    range = math.min(range, status.resource("aetheri:mana") / costMult)
    buffered = false
    
    local pos = mcontroller.position()
    local target = vec2.add(pos, vec2.mul(aimVec, range))
    local hit = world.lineCollision(pos, target)
    if hit then target = hit end
    local pol = mcontroller.collisionPoly()
    local mov = 3.5
    local corr = world.resolvePolyCollision(pol, target, mov)
    target = corr or target
    
    local distance = vec2.mag(vec2.sub(target, pos))
    if status.overConsumeResource("aetheri:mana", distance * costMult) then
      mcontroller.setPosition(target)
      mcontroller.setVelocity(vec2.mul(aimVec, math.min(range/rangeSmall, 1) * 55))
      cooldown = 1
      
      anim = {
        time = 1,
        angle = angle, dir = dir,
        distance = distance,
      }
      
      playerext.playAudio("/sfx/tech/tech_dashftl.ogg", 0, 1)
      playerext.playAudio("/sfx/tech/tech_dash.ogg", 0, 1.75)
      if hit then -- impact sound
        playerext.playAudio("/sfx/gun/grenadeblast_small_electric2.ogg", 0, 1.25)
      end
    end
  end
  
  if anim then
    playerext.queueDrawable({
      renderLayer = "player-1", fullbright = true,
      image = string.format("/aetheri/skills/blinktrail.png%s?scalebilinear=%f;%f%s", directives, anim.distance / 8, anim.time^3, anim.dir < 0 and "?flipx" or ""),
      position = {0, 0}, centered = true,
      rotation = anim.angle * anim.dir
    })
    
    
    anim.time = anim.time - (dt / animTime)
    if anim.time <= 0 then anim = nil end
  end
end
