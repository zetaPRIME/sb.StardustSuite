require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"
require "/lib/stardust/color.lua"

function init()
  script.setUpdateDelta(3) -- was 5
  
  self.drawPath = "/startech/objects/power/"
  self.dMeter = self.drawPath .. "battery.meter.png"
  
  dPos = vec2.add(objectAnimator.position(), {-1, 0})
  if objectAnimator.direction() == 1 then dPos[1] = dPos[1] + 5/8 end
  dPos = vec2.add(dPos, vec2.mul({3, 16 - 5}, 1/8))
end

function update()
  local batLevel = animationConfig.animationParameter("level") or 0 -- float, 0..1
  if batLevel == lastBatLevel then return nil end -- let's ease up a lil
  lastBatLevel = batLevel
  
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  
  localAnimator.addDrawable({
    image = table.concat({
      self.dMeter , "?addmask=", self.dMeter, ";0;",
      10 - math.floor(batLevel * 10),
      "?multiply=", color.toHex(color.fromHsl{math.max(0, batLevel*1.25 - 0.25) * 1/3, 1, 0.5, 1})
    }),
    position = vec2.add(objectAnimator.position(), { -1/8, 3/8 }),
    fullbright = true,
    centered = false,
    zlevel = 10
  })
end

--
