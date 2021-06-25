-- StardustLib.Color
require "/scripts/util.lua"

do
  local color = { }
  _ENV.color = color
  
  function color.toHex(rgb, hash)
    if not rgb then return nil end
    local h = hash and "#" or ""
    if type(rgb) == "string" then return string.format("%s%s", h, rgb:gsub("#","")) end
    return string.format(rgb[4] and "%s%02x%02x%02x%02x" or "%s%02x%02x%02x", h,
      math.floor(0.5 + rgb[1] * 255),
      math.floor(0.5 + rgb[2] * 255),
      math.floor(0.5 + rgb[3] * 255),
      math.floor(0.5 + (rgb[4] or 1.0) * 255)
    )
  end
  
  local function cl(n) return util.clamp(n, 0, 1) end
  function color.toRgb(hex)
    if type(hex) == "table" then return hex end
    hex = hex:gsub("#", "") -- strip hash if present
    local len = hex:len()
    if len == 3 or len == 4 then
      return {
        tonumber(hex:sub(1, 1), 16) / 15,
        tonumber(hex:sub(2, 2), 16) / 15,
        tonumber(hex:sub(3, 3), 16) / 15,
        (len == 4) and (tonumber(hex:sub(4, 4), 16) / 15) or nil
      }
    elseif len >= 6 and len <= 8 then
      return {
        tonumber(hex:sub(1, 2), 16) / 255,
        tonumber(hex:sub(3, 4), 16) / 255,
        tonumber(hex:sub(5, 6), 16) / 255,
        (len == 8) and (tonumber(hex:sub(7, 8), 16) / 255) or nil
      }
    end
  end
  
  local validDigits = {
    ["0"] = true, ["1"] = true, ["2"] = true, ["3"] = true, ["4"] = true,
    ["5"] = true, ["6"] = true, ["7"] = true, ["8"] = true, ["9"] = true,
    a = true, b = true, c = true, d = true, e = true, f = true,
    A = true, B = true, C = true, D = true, E = true, F = true,
  }
  function color.validateHex(hex, hash)
    if type(hex) ~= "string" then return nil end
    hex = hex:gsub("#", "") -- strip hash if present
    local len = hex:len()
    --if len < 6 then return nil end -- no short right now
    if len < 3 or len == 5 or len > 8 then return nil end -- wrong char count
    for i=1,len do
      if not validDigits[hex:sub(i, i)] then return nil end
    end
    return color.toHex(color.toRgb(hex), hash)
  end
  
  function color.toRgb255(c)
    if type(c) == "table" then return {
      math.floor(0.5 + rgb[1] * 255),
      math.floor(0.5 + rgb[2] * 255),
      math.floor(0.5 + rgb[3] * 255),
      rgb[4] and math.floor(0.5 + (rgb[4] or 1.0) * 255)
    } elseif type(c) == "string" then return color.toRgb255(color.toRgb(c)) end
  end
  
  function color.withAlpha(c, a)
    c = color.toRgb(c)
    return { c[1], c[2], c[3], a }
  end
  function color.hexWithAlpha(c, a, h) return color.toHex(color.withAlpha(c, a), h) end -- shorthand
  
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
  
  function color.alphaDirective(a)
    return string.format("?multiply=ffffff%02x", math.floor(0.5 + util.clamp(a, 0.0, 1.0) * 255))
  end
  
  -- code borrowed from https://github.com/Wavalab/rgb-hsl-rgb/blob/master/rgbhsl.lua; license unknown :(
  -- {
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
  
  local function rgbToHsl(r, g, b)
    local max, min = math.max(r, g, b), math.min(r, g, b)
    local t = max + min
    local h = t / 2
    if max == min then return 0, 0, h end
    local s, l = h, h
    local d = max - min
    s = l > .5 and d / (2 - t) or d / t
    if max == r then h = (g - b) / d % 6
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    return h * .16667, s, l
  end
  -- }
  
  function color.fromHsl(hsl)
    local c = { hslToRgb(table.unpack(hsl)) }
    c[4] = hsl[4] -- add alpha if present
    return c
  end
  
  function color.toHsl(c)
    c = color.toRgb(c)
    local hsl = { rgbToHsl(table.unpack(c)) }
    hsl[4] = c[4]
    return hsl
  end
  
  --
end
