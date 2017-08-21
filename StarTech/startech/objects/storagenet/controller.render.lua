require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

TilePixels = 8

function init()
  script.setUpdateDelta(1)
  
  self.drawPath = "/startech/objects/storagenet/"
  self.dFrame = self.drawPath .. "controller.frame.png"
  self.dGlow = self.drawPath .. "controller.glow.png"
  self.dRain = self.drawPath .. "controller.rain.png"
  self.dMask = self.drawPath .. "controller.mask.png"
  
  self.glowPos = 0
  self.glowHeight = 24
  
  self.rainPos = 0
  
  self.glowHue = 0
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
  
  self.glowPos = (self.glowPos + 0.32) % 24
  self.glowHue = (self.glowHue + 0.001) % 1.0
  
  self.rainPos = (self.rainPos + 0.24) % 24
  
  local pos = objectAnimator.position()
  pos[1] = pos[1] - 1
  local gpos = { pos[1], pos[2] + -3 + (self.glowPos / 8.0) }
  
  -- glow
  localAnimator.addDrawable({
    --image = table.concat({self.dGlow, "?addmask=", self.dMask}),
    image = table.concat({
      self.dMask,
      "?blendmult=", self.dGlow, ";0;", math.floor(self.glowHeight - self.glowPos),
      "?blendmult=", self.dRain, ";0;", math.floor(self.rainPos),
      "?multiply=", colorToString(hslToRgb(self.glowHue, 1, 0.5, 1))
    }),
    position = pos,
    fullbright = true,
    centered = false
  })
  -- frame
  localAnimator.addDrawable({
    image = self.dFrame,
    position = pos,
    fullbright = false,
    centered = false
  })
  
end
