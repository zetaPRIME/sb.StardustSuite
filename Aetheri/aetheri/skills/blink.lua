--

require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/poly.lua"





local cooldown = 0
local cooldownTime = 0.25

function init()
  activeItem.setHoldingItem(false)
  activeItem.setTwoHandedGrip(false)
end

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
    local range = buffered == "primary" and 2*25 or 2*5
    range = math.min(range, status.resource("aetheri:mana") / costMult)
    buffered = false
    
    local pos = mcontroller.position()
    local target = vec2.add(pos, vec2.mul(aimVec, range))
    local hit = world.lineCollision(pos, target)
    if hit then
      target = vec2.sub(hit, aimVec)
      local pol = mcontroller.collisionPoly()
      local mov = 3.5
      local corr = world.resolvePolyCollision(pol, target, mov)
      target = corr or target
    end
    
    if status.consumeResource("aetheri:mana", vec2.mag(vec2.sub(target, pos)) * costMult ) then
      mcontroller.setPosition(target)
      mcontroller.setVelocity(vec2.mul(aimVec, math.min(range/5, 1) * 55))
      cooldown = 1
    end
  end
end
