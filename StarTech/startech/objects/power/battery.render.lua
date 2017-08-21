require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

function init()
  script.setUpdateDelta(3) -- was 5
  
  self.drawPath = "/objects/tech/power/"
  self.dMeter = self.drawPath .. "battery.meter.png"
  
  dPos = vec2.add(objectAnimator.position(), {-1, 0})
  if objectAnimator.direction() == 1 then dPos[1] = dPos[1] + 5/8 end
  dPos = vec2.add(dPos, vec2.mul({3, 16 - 5}, 1/8))
end

function hslToRgb(h, s, l, a)
  local r, g, b

  if s == 0 then
    r, g, b = l, l, l -- achromatic
  else
    function hue2rgb(p, q, t)
      if t < 0   then t = t + 1 end
      if t > 1   then t = t - 1 end
      if t < 1/6 then return p + (q - p) * 6 * t end
      if t < 1/2 then return q end
      if t < 2/3 then return p + (q - p) * (2/3 - t) * 6 end
      return p
    end

    local q
    if l < 0.5 then q = l * (1 + s) else q = l + s - l * s end
    local p = 2 * l - q

    r = hue2rgb(p, q, h + 1/3)
    g = hue2rgb(p, q, h)
    b = hue2rgb(p, q, h - 1/3)
  end

  return {math.ceil(r * 255), math.ceil(g * 255), math.ceil(b * 255), math.ceil(a * 255)}
end
function colorToString(color)
  return string.format("%08x", color[1] * 16777216 + color[2] * 65536 + color[3] * 256 + color[4])
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
      "?multiply=", colorToString(hslToRgb(math.max(0, batLevel*1.25 - 0.25) * 1/3, 1, 0.5, 1))
    }),
    position = vec2.add(objectAnimator.position(), { -1/8, 3/8 }),
    fullbright = true,
    centered = false,
    zlevel = 10
  })
end

--
