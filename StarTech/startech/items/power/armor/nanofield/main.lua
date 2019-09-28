--

require "/scripts/vec2.lua"
require "/lib/stardust/itemutil.lua"
require "/lib/stardust/tech/input.lua"

require "/startech/items/power/armor/nanofield/stats.lua"
require "/startech/items/power/armor/nanofield/movement.lua"
require "/startech/items/power/armor/nanofield/appearance.lua"

-- armor value works differently from normal armors
-- mult = .5^(armor/100); or, every 100 points is a 50% damage reduction



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

function update(p)
  input.update(p)
  stats.update(p)
  
  movement.update(p)
  
  stats.postUpdate(p)
  appearance.update(p)
  
  if false then
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
  
  --
end

function uninit()
  movement.call("uninit")
  stats.uninit()
end
