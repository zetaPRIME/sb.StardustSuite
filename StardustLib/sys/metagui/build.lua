-- pane builder

require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/lib/stardust/sharedtable.lua"
local ipc = sharedTable "metagui:ipc"

if not _mgcfg then _mgcfg = root.assetJson("/panes.config").metaGUI end -- make sure we have this
local registry = root.assetJson("/metagui/registry.json")
getmetatable ''.metagui_root = _mgcfg.providerRoot -- shove this in here so we don't need to configure this

if pane.containerEntityId then
  if ipc.openContainerProxy then -- close and reopen next frame to prevent inventory from just closing due to openWithInventory
    ipc.openContainerProxy = nil -- dismiss this here to guard against infinite loops
    player.interact("OpenContainer", nil, pane.sourceEntity())
    return pane.dismiss()
  end
  ipc.openContainerProxy = pane.sourceEntity()
end

-- determine UI json
local uicfg = inputcfg or config.getParameter("ui") or config.getParameter("config")
if type(uicfg) == "string" then
  while uicfg and uicfg:sub(1, 1) ~= "/" do -- not path; resolve from registry
    local modname = uicfg:match('^(.-):')
    local uiname = uicfg:match(':(.+)$')
    uicfg = (registry.panes[modname] or { })[uiname]
  end
  -- still a string after resolving (if necessary)?
  if type(uicfg) == "string" then
    local fn = uicfg
    if fn:lower():match('%.([^.]-)$') == "lua" then -- build script
      inputdata = inputdata or config.getParameter("data") or { }
      require(fn) uicfg = _ENV.cfg -- execute and grab result
      -- and push in automatically
      uicfg.inputData = uicfg.inputData or { }
      util.mergeTable(uicfg.inputData, inputdata or config.getParameter("data") or { })
    else -- just a plain json doc
      uicfg = root.assetJson(fn)
      -- insert passed data, preserving defaults
      uicfg.inputData = uicfg.inputData or { }
      util.mergeTable(uicfg.inputData, inputdata or config.getParameter("data") or { })
    end
    uicfg.configPath = fn
    uicfg.assetPath = fn:match('^(.*/).-$')
  end
end
if type(uicfg) ~= "table" then
  sb.logError("metaGUI: pane not found")
  return nil -- error?
end


-- determine theme and accent color in use
local defaultTheme = registry.defaultTheme or false
if not registry.themes[defaultTheme] then for k in pairs(registry.themes) do defaultTheme = k break end end

settings = player.getProperty("metagui:settings") or player.getProperty("metaGUISettings") or { }
local theme = settings.theme or defaultTheme
if uicfg.forceTheme then theme = uicfg.forceTheme end
if not registry.themes[theme] then theme = defaultTheme end

local themedata = root.assetJson(registry.themes[theme] .. "theme.json")

local defaultAccentColor = settings.accentColor or themedata.defaultAccentColor

-- apply config to ui data
uicfg.theme = theme
uicfg.themePath = registry.themes[theme]

-- actually construct the base
uicfg.style = uicfg.style or "window" -- default window style

local borderMargins = themedata.metrics.borderMargins[uicfg.style] or themedata.metrics.borderMargins["panel"]
local size = {
  uicfg.size[1] + borderMargins[1] + borderMargins[3],
  uicfg.size[2] + borderMargins[2] + borderMargins[4]
}
uicfg.totalSize = size

-- handle unique conditions
local abort
if uicfg.uniqueBy == "path" and uicfg.configPath then
  if ipc.uniqueByPath and ipc.uniqueByPath[uicfg.configPath] then
    ipc.uniqueByPath[uicfg.configPath]()
    if uicfg.uniqueMode == "toggle" then return end
  end
end

local containerEntityId -- save in case of object destruction
if pane.containerEntityId then
  uicfg.isContainer = true
  containerEntityId = pane.containerEntityId()
  ipc.containerSync = ipc.containerSync or { }
  local cs = ipc.containerSync[containerEntityId]
  if not cs then
    cs = setmetatable({ }, { __mode = 'v' })
    ipc.containerSync[containerEntityId] = cs
  end
  cs.stub = pane.dismiss
end

local pf = { type = "panefeature" }
if type(uicfg.anchor) == "table" then
  pf.anchor = uicfg.anchor[1]
  pf.offset = vec2.mul(uicfg.anchor[2], {1, -1})
  pf.positionLocked = true
end

-- assembly aids for scroll area
local am = "/assetmissing.png"
local bhp = { base = am, hover = am, pressed = am }
local fbbhp = { forward = bhp, backward = bhp }
local bei = { begin = am, ["end"] = am, inner = am }
local bhpbei = { base = bei, hover = bei, pressed = bei }

player.interact("ScriptPane", {
  gui = {
    _ = {
      type = "background",
      fileFooter = "/assetmissing.png?crop=0;0;1;1?multiply=0000?scalenearest=" .. size[1] .. ";" .. size[2]
    },
    _pf = pf,
    _tracker = { type = "canvas", size = size, zlevel = -99999 },
    _mouse = { type = "canvas", size = size, zlevel = -99995, captureMouseEvents = true },
    _wheel = { type = "scrollArea", position = {99999999, 0}, size = size, zlevel = -99997, verticalScroll = false },
  },
  scripts = { _mgcfg.providerRoot .. "core.lua" },
  scriptWidgetCallbacks = { "__cb1", "__cb2", "__cb3", "__cb4", "__cb5", "_clickLeft", "_clickRight" },
  canvasClickCallbacks = { _mouse = "_mouseEvent" },
  openWithInventory = uicfg.openWithInventory or uicfg.isContainer,
  closeWithInventory = (function() if uicfg.isContainer then return false end end)(),
  ___ = uicfg
}, pane.sourceEntity())

local _uninit = uninit
function uninit(...)
  if _uninit then _uninit(...) end
  if containerEntityId then
    local cs = ipc.containerSync[containerEntityId]
    cs.stub = nil
    if cs.pane then cs.pane() end
  end
end
