-- Frackin' Standard theme

local mg = metagui
local assets = theme.assets

assets.windowBorder = mg.ninePatch "windowBorder"
assets.windowBg = mg.asset "windowBg.png"
assets.buttonColored = mg.ninePatch "button"--Colored"

local color = { } do -- mini version of StardustLib's color.lua
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
  
  function color.replaceDirective(from, to, continue)
    local l = continue and { } or { "?replace" }
    local num = math.min(#from, #to)
    for i = 1, num do table.insert(l, string.format(";%s=%s", color.toHex(from[i]), color.toHex(to[i]))) end
    return table.concat(l)
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
end

local td = 360
sb.logInfo("rgb hues: " .. util.tableToString {
  color.toHsl "ff0000"[1] * td,
  color.toHsl "00ff00"[1] * td,
  color.toHsl "0000ff"[1] * td
})

local hueShift do
  local baseHue = color.toHsl(theme.defaultAccentColor)[1]
  local accHsl = color.toHsl(mg.getColor("accent"))
  local accHue = accHsl[2] > 0 and accHsl[1] or baseHue
  --sb.logInfo(util.tableToString{baseHue, accHue})
  hueShift = string.format("?hueshift=%d", math.floor((1.0 + accHue - baseHue) * 360))
end

local basePal = { "588adb", "123166", "0d1f40" }
local pals = { }--[theme.defaultAccentColor] = "" }
local bgAlpha = 0.9
local function paletteFor(col)
  col = mg.getColor(col)
  if pals[col] then return pals[col] end
  local h, s, l = table.unpack(color.toHsl(col))
  local function c(v) return util.clamp(v, 0, 1) end
  local r = color.replaceDirective(basePal, {
    col, -- highlight
    color.fromHsl{h, c(s * 1.11), c(l * 0.39), bgAlpha}, -- bg
    color.fromHsl{h, c(s * 1.04), c(l * 0.25), bgAlpha} -- bg dark
  })
  
  --
  
  pals[col] = r
  return r
end

local titleBar, icon, title, close, spacer
function theme.decorate()
  local style = mg.cfg.style
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
  
  if (style == "window") then
    titleBar = frame:addChild { type = "layout", position = {6, 2}, size = {frame.size[1] - 24 - 5, 23}, mode = "horizontal" }
    icon = titleBar:addChild { type = "image" }
    spacer = titleBar:addChild { type = "spacer", size = 0 }
    spacer.expandMode = {0, 0}
    title = titleBar:addChild { type = "label", expand = true, align = "left" }
    close = frame:addChild{
      type = "iconButton", position = {frame.size[1] - 24, 8},
      image = "/interface/x.png", hoverImage = "/interface/xhover.png", pressImage = "/interface/xpress.png"
    }
    function close:onClick()
      pane.dismiss()
    end
  end
end

function theme.drawFrame()
  local style = mg.cfg.style
  c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  c:clear() --assets.frame:drawToCanvas(c)
  
  local pal = paletteFor("accent")
  
  if (style == "window") then
    local bgClipWindow = rect.withSize({4, 4}, vec2.sub(c:size(), {4+6, 4+4}))
    c:drawTiledImage(assets.windowBg .. pal, {0, 0}, bgClipWindow)
    
    --assets.windowBorder:drawToCanvas(c, "frame?multiply=" .. mg.getColor("accent"))
    assets.windowBorder:drawToCanvas(c, "frame" .. hueShift)
    
    spacer.explicitSize = (not mg.cfg.icon) and -2 or 1
    icon.explicitSize = (not mg.cfg.icon) and {-1, 0} or nil
    icon:setFile(mg.cfg.icon)
    title:setText("^shadow;" .. mg.cfg.title:gsub('%^reset;', '^reset;^shadow;'))
  else assets.frame:drawToCanvas(c) end
end

function theme.drawButton(w)
  local c = widget.bindCanvas(w.backingWidget)
  c:clear()
  local acc = mg.getColor(w.color)
  if acc then
    assets.buttonColored:drawToCanvas(c, (w.state or "idle") .. "?multiply=" .. acc)
  else
    assets.button:drawToCanvas(c, w.state or "idle")
  end
  theme.drawButtonContents(w)
end
