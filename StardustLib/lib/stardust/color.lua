-- StardustLib.Color
require "/scripts/util.lua"

do
  color = { }
  
  function color.toHex(rgb, hash)
    local h = hash and "#" or ""
    if type(rgb) == "string" then return string.format("%s%s", h, rgb:gsub("#","")) end
    return string.format(rgb[4] and "%s%02x%02x%02x%02x" or "%s%02x%02x%02x", h,
      math.floor(0.5 + rgb[1] * 255),
      math.floor(0.5 + rgb[2] * 255),
      math.floor(0.5 + rgb[3] * 255),
      math.floor(0.5 + (rgb[4] or 1.0) * 255)
    )
  end
  
  function color.toRgb(hex)
    if type(hex) == "table" then return hex end
    hex = hex:gsub("#", "") -- strip hash if present
    return {
      tonumber(hex:sub(1, 2), 16) / 255,
      tonumber(hex:sub(3, 4), 16) / 255,
      tonumber(hex:sub(5, 6), 16) / 255,
      (hex:len() == 8) and (tonumber(hex:sub(7, 8), 16) / 255)
    }
  end
  
  function color.toRgb255(c)
    if type(c) == "table" then return {
      math.floor(0.5 + rgb[1] * 255),
      math.floor(0.5 + rgb[2] * 255),
      math.floor(0.5 + rgb[3] * 255),
      rgb[4] and math.floor(0.5 + (rgb[4] or 1.0) * 255)
    } elseif type(c) == "string" then
      hex = c:gsub("#", "") -- strip hash if present
      return {
      tonumber(hex:sub(1, 2), 16),
      tonumber(hex:sub(3, 4), 16),
      tonumber(hex:sub(5, 6), 16),
      (hex:len() == 8) and (tonumber(hex:sub(7, 8), 16))
    } end
  end
  
  function color.brighterOf(a, b)
    local ca, cb = color.toRgb(a), color.toRgb(b)
    return ( (ca[1] + ca[2] + ca[3]) * (ca[4] or 1) >= (cb[1] + cb[2] + cb[3]) * (cb[4] or 1) ) and a or b
  end
  
  function color.darkerOf(a, b)
    local ca, cb = color.toRgb(a), color.toRgb(b)
    return ( (ca[1] + ca[2] + ca[3]) * (ca[4] or 1) >= (cb[1] + cb[2] + cb[3]) * (cb[4] or 1) ) and b or a
  end
  
  function color.lightColor(c, brightness)
    c = color.toRgb(c)
    local m = (brightness or c[4] or 1.0) * 255
    return { c[1] * m, c[2] * m, c[3] * m }
  end
  
  function color.replaceDirective(from, to, continue)
    local l = continue and { } or { "?replace" }
    local num = math.min(#from, #to)
    for i = 1, num do table.insert(l, string.format(";%s=%s", color.toHex(from[i]), color.toHex(to[i]))) end
    return table.concat(l)
  end
  
  function color.hideDirective(src, continue)
    local l = continue and { } or { "?replace" }
    for _, c in pairs(src) do table.insert(l, string.format(";%s=00000000", color.toHex(c))) end
    return table.concat(l)
  end
  
  -- code borrowed from https://github.com/Wavalab/rgb-hsl-rgb/blob/master/rgbhsl.lua; license unknown :(
  local function hslToRgb(h, s, l)
    if s == 0 then return l, l, l end
    local function to(p, q, t)
        if t < 0 then t = t + 1 end
        if t > 1 then t = t - 1 end
        if t < .16667 then return p + (q - p) * 6 * t end
        if t < .5 then return q end
        if t < .66667 then return p + (q - p) * (.66667 - t) * 6 end
        return p
    end
    local q = l < .5 and l * (1 + s) or l + s - l * s
    local p = 2 * l - q
    return to(p, q, h + .33334), to(p, q, h), to(p, q, h - .33334)
  end
  
  function color.fromHsl(hsl)
    local c = { hslToRgb(table.unpack(hsl)) }
    c[4] = hsl[4] -- add alpha if present
    return c
  end
  
  --
end
