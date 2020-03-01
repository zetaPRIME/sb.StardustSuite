require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

function init()
  script.setUpdateDelta(3) -- was 5
  
  self.drawPath = "/startech/objects/storagenet/"
  self.dLight = self.drawPath .. "drivebay.light.png?multiply=00FF00"
  self.dLightLegacy = self.drawPath .. "drivebay.light.png?multiply=FF3F3F"
  
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
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  
  local lightStates = animationConfig.animationParameter("lights", {})
  if not lightStates then return nil end
  local legacy = animationConfig.animationParameter("isLegacy", false)
  
  for i,v in pairs(lightStates) do
  i = i - 1 -- 0-indexed pls
  local ddPos = vec2.add(dPos, vec2.mul({
      (i % 2) * 3,
      math.floor(i/2) * -2
    }, 1/8))
    localAnimator.addDrawable({
      image = legacy and self.dLightLegacy or self.dLight,
      position = ddPos,
      fullbright = true,
      centered = false,
      zlevel = 100
    })
  end
end

--
