-- pane builder

if not _mgcfg then _mgcfg = root.assetJson("/panes.config").metaGUI end -- make sure we have this
local registry = root.assetJson("/metagui/registry.json")

-- determine UI json
local uicfg = config.getParameter("config")
if type(uicfg) == "string" then
  while uicfg and uicfg:sub(1, 1) ~= "/" do -- not path; resolve from registry
    local modname = uicfg:match('^(.-):')
    local uiname = uicfg:match(':(.+)$')
    uicfg = (registry.panes[modname] or { })[uiname]
  end
  -- still a string after resolving (if necessary)?
  if type(uicfg) == "string" then uicfg = root.assetJson(uicfg) end
end
if type(uicfg) ~= "table" then
  return nil -- error?
end

-- determine theme and accent color in use
local defaultTheme = _mgcfg.defaultTheme
if not registry.themes[defaultTheme] then for k in pairs(registry.themes) do defaultTheme = k break end end

playercfg = status.statusProperty("metaGUI") or { }
local theme = playercfg.theme or defaultTheme
if not registry.themes[theme] then theme = defaultTheme end

local themedata = root.assetJson(registry.themes[theme] .. "theme.json")

local defaultAccentColor = playercfg.accentColor or themedata.defaultAccentColor

-- apply config to ui data
uicfg.theme = theme
uicfg.themePath = registry.themes[theme]
uicfg.accentColor = uicfg.accentColor or defaultAccentColor

-- actually construct the base
uicfg.style = uicfg.style or "window" -- default window style

local borderMargins = themedata.metrics.borderMargins[uicfg.style]
local size = {
  uicfg.size[1] + borderMargins[1] + borderMargins[3],
  uicfg.size[2] + borderMargins[2] + borderMargins[4]
}
uicfg.totalSize = size

player.interact("ScriptPane", {
  gui = {
    _ = {
      type = "background",
      fileFooter = "/assetmissing.png?crop=0;0;1;1?multiply=0000?scalenearest=" .. size[1] .. ";" .. size[2]
    }
  },
  scripts = { "/sys/metagui/core.lua" },
  scriptWidgetCallbacks = { "__cb1", "__cb2", "__cb3", "__cb4", "__cb5" },
  ___ = uicfg
}, pane.sourceEntity())
