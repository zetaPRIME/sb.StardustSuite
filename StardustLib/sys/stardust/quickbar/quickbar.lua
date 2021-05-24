--

require "/scripts/util.lua"
require "/sys/stardust/quickbar/conditions.lua"

local actions = { }
qbActions = actions -- alias in global for execs
local function nullfunc() end
local function action(id, ...) return (actions[id] or nullfunc)(...) end

-------------
-- actions --
-------------

function actions.pane(cfg)
  if type(cfg) ~= "table" then cfg = { config = cfg } end
  player.interact(cfg.type or "ScriptPane", cfg.config)
end

function actions.ui(cfg, data) -- metaGUI
  player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = cfg, data = data })
end

function actions.exec(script, ...)
  if type(script) ~= "string" then return nil end
  params = {...} -- pass any given parameters to the script
  _SBLOADED[script] = nil require(script) -- force execute every time
  params = nil -- clear afterwards for cleanliness
end

function actions._legacy_module(s)
  local m, e = (function() local it = string.gmatch(s, "[^:]+") return it(), it() end)()
  local mf = string.format("/quickbar/%s.lua", m)
  module = { }
  _SBLOADED[mf] = nil require(mf) -- force execute
  module[e]() module = nil -- run function and clean up
end

---------------
-- internals --
---------------

local function menuClick(w)
  w:deselect()
  local i = metagui.cfg.itemDefs[w.id]
  if i.condition and not condition(table.unpack(i.condition)) then return nil end -- recheck condition on attempt
  action(table.unpack(i.action))
  if autoDismiss or i.dismissQuickbar then pane.dismiss() end
end

for _, w in pairs(itemField.children[1].children) do
  if w.widgetType == "listItem" then w.onSelected = menuClick end
end
