require "/lib/stardust/dynitemanim.lua"
require "/startech/items/active/weapons/pulseweapon.lua"

function init() initPulseWeapon()
  --
end

function uninit()
  if status.statPositive "stardustlib:customFlying" then
    local t = 0.3
    mcontroller.setRotation(math.max(-t, math.min(t, mcontroller.rotation())))
  else mcontroller.setRotation(0) end
end


dynItem.install()
dynItem.setAutoAim(false)

function idle()
  activeItem.setCursor()
  
  while true do
    dynItem.aimAt(dynItem.aimDir, 0)
    activeItem.setHoldingItem(false)
    
    if dynItem.firePress then dynItem.firePress = false return kick end
    if dynItem.altFirePress then dynItem.altFirePress = false return thrust, true end -- for now just skip to the finisher
    coroutine.yield()
  end
end dynItem.comboSystem(idle)

local buffered, released
local function inp()
  if dynItem.firePress then buffered = true end
  if not dynItem.fire then released = true end
end

function kick()
  local mparams = {
    airJumpProfile = {
      jumpSpeed = 0,
    },
  }
  
  --[[for v in dynItem.tween(0.1) do
    mcontroller.controlCrouch()
  end--]]
  
  dynAnim.setArmStates("in")
  dynAnim.setArmAngles(math.pi * 2/8)
  activeItem.setHoldingItem(true)
  
  mcontroller.controlParameters(mparams)
  
  mcontroller.controlJump(true)
  mcontroller.setYVelocity(math.max(25, mcontroller.yVelocity()))
  for v in dynItem.tween(0.45) do inp()
    mcontroller.controlParameters(mparams)
    --mcontroller.controlHoldJump()
    
    local vv = v^0.4
    mcontroller.setRotation(vv * math.pi * 2 * dynItem.dir)
    --activeItem.setArmAngle(0)
    --mcontroller.setYVelocity(20 * (1-vv*1.5))
  end
  mcontroller.setRotation(0)
  mcontroller.clearControls()
end
