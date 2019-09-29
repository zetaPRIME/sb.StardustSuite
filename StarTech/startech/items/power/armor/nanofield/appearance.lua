--

require "/lib/stardust/color.lua"

appearance = { }

local wingFront = Prop.new(2)
local wingBack = Prop.new(-2)
local wingAlpha = 0
local wingEffDir = 1.0
local wingsVisible = false
local wingEnergyColor
local wingBaseRot = 0

wingFront:scale({0, 0})
wingBack:scale({0, 0})

function appearance.update(p)

  do -- wings
    local ta = wingsVisible and 1.0 or 0.0
    if wingAlpha ~= ta then
      wingAlpha = util.clamp(wingAlpha + (ta*2 - 1) * 5 * p.dt, 0.0, 1.0)
      local ov = util.clamp(wingAlpha * 1.5, 0.0, 1.0)
      local fv = util.clamp(-.5 + wingAlpha * 1.5, 0.0, 1.0)
      local fade = string.format("%s?fade=%s;%.3f", color.alphaDirective(ov), color.toHex(wingEnergyColor or "ffffff"), (1.0 - fv))
      wingFront:setDirectives(fade)
      wingBack:setDirectives(fade .. "?brightness=-40")
    end
    
    wingFront:scale({mcontroller.facingDirection() * wingEffDir, 1.0}, {0.0, 0.0})
    wingBack:scale({mcontroller.facingDirection() * wingEffDir, 1.0}, {0.0, 0.0})
    wingEffDir = mcontroller.facingDirection()
  end
end

function appearance.setWings(w)
  wingFront:setImage("elytra.png")
  wingBack:setImage("elytra.png")
  wingEnergyColor = w.energyColor
  wingBaseRot = w.baseRotation or 0
  
  wingAlpha = wingAlpha - 0.001 -- kick things a bit
end

function appearance.setWingsVisible(f) wingsVisible = not not f end

function appearance.positionWings(r)
  local offset = {-5 / 16, -15 / 16}
  wingFront:resetTransform()
  wingBack:resetTransform()
  
  -- base rotation first
  wingFront:rotate(wingBaseRot)
  wingBack:rotate(wingBaseRot)
  
  -- rotate wings relative to attachment
  wingFront:rotate(r * math.pi * .14)
  wingBack:rotate(r * math.pi * .07)
  wingBack:rotate(-0.11)
  
  -- then handle attachment sync
  wingFront:translate(offset)
  wingFront:rotate(mcontroller.rotation() * mcontroller.facingDirection())
  wingBack:translate(offset)
  wingBack:translate({3 / 16, 0 / 16})
  wingBack:rotate(mcontroller.rotation() * mcontroller.facingDirection())
  wingEffDir = 1.0
end
