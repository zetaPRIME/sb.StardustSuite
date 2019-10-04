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

local fieldAlpha = 0
local fieldColor = "9771e4"
local energyPalette = { }

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
  
  if fieldAlpha > 0 then
    fieldAlpha = fieldAlpha - p.dt * 3
    local a = util.clamp(fieldAlpha, 0.0, 1.0)
    if a == 0 then
      tech.setParentDirectives("")
    else
      tech.setParentDirectives(string.format("?border=1;%s;0000", color.hexWithAlpha(energyPalette[2] or fieldColor, a)))
    end
  end
end

function appearance.setEnergyColor(c)
  if not c then energyPalette = { } else
    local h, s, l, a = table.unpack(color.toHsl(c))
    energyPalette = {
      color.fromHsl {h, s, math.min(l * 75, 0.9), a },
      c,
      color.fromHsl {h, s, l * 0.64, a },
    }
  end
  world.sendEntityMessage(entity.id(), "startech:refreshEnergyColor")
end

message.setHandler("startech:getEnergyColor", function() return energyPalette[1] and energyPalette or nil end)

function appearance.pulseForceField(amt)
  fieldAlpha = math.max(fieldAlpha, (amt or 1.0) + script.updateDt() * 3)
end

function appearance.setWings(w)
  wingFront:setImage("elytra.png")
  wingBack:setImage("elytra.png")
  wingEnergyColor = w.energyColor
  wingBaseRot = w.baseRotation or 0
  
  appearance.setEnergyColor(w.energyColor)
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
