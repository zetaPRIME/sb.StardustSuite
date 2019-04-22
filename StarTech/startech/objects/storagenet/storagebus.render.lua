require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

TilePixels = 8

function init()
  script.setUpdateDelta(3) -- was 5
  
  self.drawPath = "/startech/objects/storagenet/"
  self.dGlow = self.drawPath .. "storagebus.glow.png"
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

rot = {
  0,
  math.pi * 1.5,
  math.pi * 1,
  math.pi * .5
}

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function update()
  localAnimator.clearDrawables()
  localAnimator.clearLightSources()
  
  local pos = vec2.add(objectAnimator.position(), {0.5, 0.5})
  
  -- glow
  localAnimator.addDrawable({
    image = self.dGlow,
    position = pos,
    rotation = rot[animationConfig.animationParameter("orientation", 1)],
    fullbright = true,
    centered = true,
    zlevel = 1000000
  })
  
end

--
