require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

TilePixels = 8

function init()
  script.setUpdateDelta(1)
  
  self.drawPath = "/objects/tech/storagenet/"
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

function bleh()
  local requireProjectile = objectAnimator.animationParameter("requireProjectile")
  for _,beam in pairs(objectAnimator.animationParameter("beams")) do
    local hasProjectile = false
    if beam.startProjectile then
      hasProjectile = hasProjectile or world.entityExists(beam.startProjectile)
      beam.startPosition = world.entityPosition(beam.startProjectile) or beam.startPosition
    end
    if beam.endProjectile then
      hasProjectile = hasProjectile or world.entityExists(beam.endProjectile)
      beam.endPosition = world.entityPosition(beam.endProjectile) or beam.endPosition
    end

    if hasProjectile or not requireProjectile then
      local length = math.max(world.magnitude(beam.endPosition, beam.startPosition), self.minLength)
      local angle = vec2.angle(world.distance(beam.endPosition, beam.startPosition))
      local bodyLength = length - self.minLength

      local drawables = {
        {
          image = self.beamImages.first,
          position = {0, -self.startSize[2] / 2},
          fullbright = true,
          centered = false
        },
        {
          image = self.beamImages.body,
          position = {length - self.endSize[1] - bodyLength, -self.startSize[2] / 2},
          fullbright = true,
          centered = false,
          transformation = {
           {math.ceil(bodyLength * TilePixels), 0, 0},
           {0, 1, 0},
           {0, 0, 1}
         }
        },
        {
          image = self.beamImages.last,
          position = {length - self.endSize[1], -self.endSize[2] / 2},
          fullbright = true,
          centered = false
        }
      }

      for _,drawable in pairs(drawables) do
        drawable.rotation = angle
        drawable.position = vec2.add(vec2.rotate(drawable.position, angle), beam.startPosition)
        localAnimator.addDrawable(drawable)
      end

      if self.light then
        for x = 0, length, 3 do
          localAnimator.addLightSource({
            position = vec2.add(vec2.rotate({x, 0}, angle), beam.startPosition),
            color = self.light
          })
        end
      end
    end
  end
end
