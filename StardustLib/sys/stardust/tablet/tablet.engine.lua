require "/scripts/vec2.lua"

require "/lib/stardust/sync.lua"

--

function dump(o, ind)
  if not ind then ind = 2 end
  local pfx, epfx = "", ""
  for i=1,ind do pfx = pfx .. " " end
  for i=3,ind do epfx = epfx .. " " end
  if type(o) == 'table' then
    local s = '{\n'
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. pfx .. '['..k..'] = ' .. dump(v, ind+2) .. ',\n'
    end
    return s .. epfx .. '}'
  else
    return tostring(o)
  end
end

--

do
  local realEnv = _ENV
  local vec2 = vec2 -- rescope
  local table = table
  
  local function _dummyfunc() end
  
  local envWrapper = setmetatable({
    init = _dummyfunc,
    update = _dummyfunc,
  }, { __index = realEnv })
  
  --local appBaseEnv = false
  
  local osstate = {
    fgApp = false,
    openApps = {},
    drawQueue = {},
    input = {
      keys = {}, keysLast = {},
      mouse = {}, mouseLast = {},
      mousePos = { 0, 0 }
    },
    appCallStack = {}
  }
  
  input = { }
  function input.keyPressed(key)
    return (osstate.input.keys[key] and not osstate.input.keysLast[key]) or false
  end
  function input.keyHeld(key)
    return osstate.input.keys[key] or false
  end
  function input.mousePressed(key)
    return (osstate.input.mouse[key] and not osstate.input.mouseLast[key]) or false
  end
  function input.mouseHeld(key)
    return osstate.input.mouse[key] or false
  end
  function input.mousePos() return osstate.input.mousePos end
  function input.keyState() return osstate.input.keys end
  function input.mouseState() return osstate.input.mouse end

  sdos = { } -- Stardust OS
  
  local function callApp(app, funcName, ...)
    if not app or not funcName or not app[funcName] then return nil end
    table.insert(osstate.appCallStack, 1, app) -- push
    local result = {pcall(app[funcName], table.unpack({...}))}
    table.remove(osstate.appCallStack, 1) -- pop
    if result[1] then return table.unpack(result, 2) end
    sb.logWarn("app error: " .. result[2])
  end
  
  local function transitionTo(appName)
    if osstate.fgApp == appName then return nil end
    --osstate.openApps[osstate.fgApp]
    -- notify previous app
    if osstate.fgApp then callApp(osstate.openApps[osstate.fgApp], "onUnfocus") end
    osstate.fgApp = appName
    -- notify new app
    callApp(osstate.openApps[osstate.fgApp], "onFocus")
  end
  
  local function resolveAsset(path, header)
    header = header or _appHeader
    if path:sub(1,1) == "/" then return path end
    return header.basePath .. path -- hmm.
  end
  
  function sdos.launchApp(appName, background)
    local app = osstate.openApps[appName]
    if app then -- already open
      if not background then transitionTo(appName) end
      return app
    end
    local appHeader = sdos.appRegistry[appName]
    appHeader.basePath = appHeader.basePath or "/tablet/apps/" .. appName .. "/" -- might as well have a default
    --sb.logInfo("app: " .. resolveAsset(appHeader.mainScript or "app.lua", appHeader))
    local appFile = resolveAsset(appHeader.mainScript or "app.lua", appHeader)
    _SBLOADED[appFile] = nil -- force load
    __modlayer = setmetatable({}, { __index = envWrapper } )
    __app = setmetatable({}, { __index = __modlayer }) app = __app
    table.insert(osstate.appCallStack, 1, app) -- push this so imports work!
    require(appFile)
    table.remove(osstate.appCallStack, 1) -- pop
    app.__modlayer = __modlayer
    __modlayer = nil __app = nil -- cleanup
    app._appHeader = appHeader
    osstate.openApps[appName] = app
    callApp(app, "init")
    if not background then transitionTo(appName) end
    return app
  end
  
  function import(moduleName)
    local appEnv = osstate.appCallStack[1] or _ENV
    
    if not appEnv.__modlayer._active then appEnv.__modlayer._active = {} end
    if appEnv.__modlayer._active[moduleName] then return nil end
    
    if not _modules then _modules = {} end
    if not _modules[moduleName] then
      __module = setmetatable({}, { __index = _ENV })
      local success = pcall(require, "/tablet/modules/" .. moduleName .. ".lua")
      if not success then return nil end
      _modules[moduleName] = __module
      __module = nil
    end
    
    local module = _modules[moduleName]
    for k,v in pairs(module) do appEnv.__modlayer[k] = v end -- import into namespace layer
    appEnv.__modlayer._active[moduleName] = true -- mark already-loaded
  end
  
  gfx = {}
  local screenSize = { 160, 256 } -- 240 plus 16 for softkeys
  local function translateVec(v)
    return { v[1], 256 - v[2] }
  end
  local function translateRect(r) -- topleft xywh to bottomleft corner-corner
    return { r[1], 256 - r[2], r[1] + r[3], 256 - (r[2] + r[4]) }
  end
  
  function gfx.drawImage(img, pos, scale, centered)
    table.insert(osstate.drawQueue, {
      centered and "imageCentered" or "image",
      resolveAsset(img),
      translateVec(pos),
      scale
    })
  end
  function gfx.drawImageRect(img, src, dest, color)
    table.insert(osstate.drawQueue, {
      "imageRect",
      resolveAsset(img),
      src,--translateRect(src),
      translateRect(dest),
      color or {255, 255, 255}
    })
  end
  function gfx.drawRect(dest, color)
    table.insert(osstate.drawQueue, {
      "rect",
      translateRect(dest),
      color or {255, 255, 255}
    })
  end
  function gfx.drawTextDefault(text, pos, params)
    local par = { position = translateVec(pos) }
    if params then for k,v in pairs(params) do par[k] = v end end
    local fsize = par.size or 8
    local color = par.color or {255, 255, 255}
    par.size = nil par.color = nil -- clear out clutter
    table.insert(osstate.drawQueue, {
      "text",
      text,
      par,
      fsize,
      color
    })
  end
  
  local function initFont(name)
    if not sdos.fontRegistry[name or ""] then name = "default" end
    if name == "default" then name = sdos.fontRegistry[name] end
    local font = sdos.fontRegistry[name]
    font.name = name -- might as well
    if not font.chardict then
      local d = {}
      font.chardict = d
      for i = 1, font.chars:len() do
        d[font.chars:sub(i, i)] = i-1
        --table.concat({ "/tablet/fonts/", name, ".png:", i-1 })
      end
    end
    return name
  end
  local function getFont(name) return sdos.fontRegistry[initFont(name)] end
  
  function gfx.measureString(text, fontName)
    local font = getFont(fontName)
    local w = 0
    
    for c in text:gmatch(".") do
      if font.chardict[c] then
        w = w + (font.charWidth[c] or font.charWidth.default) + font.charSpacing
      end
    end
    w = w - font.charSpacing -- remove endspace
    return w * font.baseScale
  end
  
  function gfx.drawText(text, pos, fontName, params)
    local par = {}
    if params then for k,v in pairs(params) do par[k] = v end end
    local color = par.color or {255, 255, 255}
    
    local font = getFont(fontName)
    local img = "/tablet/fonts/" .. font.name .. ".png:" -- : for frame select
    local fs = font.frameSize
    local fsrc = {0, fs[2], fs[1], 0} -- {0, 0, fs[1], fs[2]}
    local bs = font.baseScale
    
    local cmdOut = { "font", img, fsrc, color }
    local icmd = #cmdOut + 1
    
    local ix = 0
    local iy = 0
    text = text .. "\n" -- force end match
    for ln in text:gmatch("([^\n]*)\n") do
      ix = 0
      if par.centered then ix = gfx.measureString(ln, fontName) * -0.5 end
      for c in ln:gmatch(".") do
        if font.chardict[c] then
          --gfx.drawImageRect(img .. font.chardict[c], fsrc, {pos[1] + (ix * bs), pos[2] + (iy * bs), fs[1] * bs, fs[2] * bs}, color)
          cmdOut[icmd] = {
            font.chardict[c], translateRect({pos[1] + (ix * bs), pos[2] + (iy * bs), fs[1] * bs, fs[2] * bs})
          } icmd = icmd + 1
          ix = ix + (font.charWidth[c] or font.charWidth.default) + font.charSpacing
        end
      end
      iy = iy + (font.fullHeight + font.lineSpacing)
    end
    
    table.insert(osstate.drawQueue, cmdOut)
  end
  
  local svc = {}
  
  function svc.uiUpdate(msg, isLocal, inp)
    -- update input state
    osstate.input.keysLast = osstate.input.keys
    osstate.input.keys = inp.key
    osstate.input.mouseLast = osstate.input.mouse
    osstate.input.mouse = inp.mouse
    osstate.input.mousePos = inp.mousePos
    
    -- then handle the update itself
    osstate.drawQueue = {}
    --gfx.drawRect({2, 2, 32, 32})
    callApp(osstate.sysUI, "uiPreUpdate")
    callApp(osstate.openApps[osstate.fgApp], "uiUpdate")
    callApp(osstate.sysUI, "uiPostUpdate")
    return { draw = osstate.drawQueue }
  end
  
  --
  
  function init()
    -- load in registries
    sdos.appRegistry = root.assetJson("/tablet/apps/apps.json")
    sdos.fontRegistry = root.assetJson("/tablet/fonts/fonts.json")
    
    -- register service messages
    for name,func in pairs(svc) do
      if type(func) == "function" then
        message.setHandler("sdltablet:" .. name, func)
      end
    end
    
    -- and init app system
    sdos.launchApp("sysUI")
    osstate.sysUI = osstate.openApps["sysUI"]
  end
  
  function update()
    for k,v in pairs(osstate.openApps) do callApp(v, "update") end
  end
  
end

--

function questStart()
  
end
