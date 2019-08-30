-- StardustLib nav extension

navExt = { }

local _cb = { }
function _callback(id, ...) return _cb[id](...) end

local _tt = { }
local _createTooltip = createTooltip
function createTooltip(pos)
  local tt = _tt[widget.getChildAt(pos)]
  if tt == nil then return _createTooltip(pos) end
  if type(tt) == "function" then return tt() end
  return tt
end

local function stripped(tbl)
  local nt = { }
  for k, v in pairs(tbl) do
    if type(v) ~= "function" then nt[k] = v end
  end
  return nt
end

local _init = init or function() end
function init(...)
  _init(...)
  
  -- find proper entity ID to bind future panes to
  navExt.bindId = pane.sourceEntity()
  if not navExt.bindId or navExt.bindId == 0 then navExt.bindId = player.id() end
  
  -- remove bars if present from before a reload
  pane.removeWidget("stardustlib:topBar")
  pane.removeWidget("stardustlib:bottomBar")
  -- and initialize them anew
  pane.addWidget({
    type = "layout",
    layoutType = "flow",
    position = {129, 320},
    size = {242, 23},
    spacing = {2, 0},
    scissoring = false,
    direction = "left",
    zlevel = 500,
  }, "stardustlib:topBar")
  pane.addWidget({
    type = "layout",
    layoutType = "flow",
    position = {5, 9},
    size = {386, 14},
    spacing = {2, 0},
    scissoring = false,
    zlevel = 500,
  }, "stardustlib:bottomBar")
  
  local barProto = { }
  topBar = setmetatable({ root = "stardustlib:topBar" }, { __index = barProto })
  bottomBar = setmetatable({ root = "stardustlib:bottomBar" }, { __index = barProto })
  
  function barProto:addWidget(w, name)
    if w.type == "button" then
      local func = w.callback or function() end
      if not name then name = "btn" .. sb.nrand() end
      w.callback = "_callback"
      _cb[name] = func
      
      if w.icon then -- automatic formatting for icon
        w.base = w.icon
        w.hover = w.icon .. "?brightness=50?saturation=-20"
        w.pressed = w.icon .. "?brightness=-50"
        w.pressedOffset = {0, 0}
      end
    end
    
    local tt = w.toolTip or w.tooltip
    if not name then name = "w" .. sb.nrand() end
    widget.addChild(self.root, stripped(w), name)
    local fullName = string.format("%s.%s", self.root, name)
    if tt then _tt["."..fullName] = tt end
    return fullName
  end
  
  function barProto:separator()
    self:addWidget { type = "image", file = "/sys/stardust/navext.separator.png" }
  end
  
  -- define stock actions
  navExt.stockIcons = { }
  function navExt.stockIcons.openSAIL()
    bottomBar:addWidget {
      type = "button", icon = "/objects/ship/techstation/apexrecordplayericon.png?crop=2;2;14;16",
      toolTip = "Open SAIL interface",
      callback = function()
        -- use the actual SAIL panel interact data so SAIL replacements work
        local ts = root.itemConfig({ name = "techstation", count = 1, parameters = { } }).config
        player.interact(ts.interactAction, ts.interactData, navExt.bindId)
        pane.dismiss()
      end,
    }
    return navExt.stockIcons
  end
  
  function navExt.stockIcons.teleporter()
    bottomBar:addWidget {
      type = "button", icon = "/interface/bookmarks/icons/beamdown.png?crop=2;2;14;16",
      toolTip = "Teleporter",
      callback = function()
        player.interact("OpenTeleportDialog", "/interface/warping/shipteleporter.config", navExt.bindId)
        pane.dismiss()
      end,
    }
    return navExt.stockIcons
  end
  
  --widget.addChild("stardustlib:topBar", { type = "image", file = "/items/generic/other/solidfuel.png" }, "testIcon")
  --widget.addChild("stardustlib:topBar", { type = "image", file = "/items/generic/other/solidfuel.png" }, "testIcon2")
  
  local fuelTip = "Fuel level"
  
  bottomBar:addWidget({ type = "image", toolTip = fuelTip, file = "/items/generic/other/solidfuel.png?crop=3;3;13;15" }, "fuelIcon")
  bottomBar:addWidget({ type = "label", toolTip = fuelTip, vAnchor = "mid" }, "fuelGauge");
  
  -- species specific module code
  local modules = config.getParameter("stardustlib:speciesModules")
  local module = modules[player.species()] or modules.default
  if type(module) == "string" then require(module) end
end

local _update = update or function() end
local alreadyOpen = false
function update(...)
  if player.worldId() == player.ownShipWorldId() then -- in own ship; read fuel values
    alreadyOpen = true
    widget.setText("stardustlib:bottomBar.fuelGauge", string.format("%i/%i", math.floor(world.getProperty("ship.fuel", 0)), math.floor(world.getProperty("ship.maxFuel", 0))))
    --local sh = widget.getSize("background") or {-12, -34}
    --widget.setText("stardustlib:bottomBar.fuelGauge", string.format("%ix%i", math.floor(sh[1]), math.floor(sh[2])))
  elseif player.isAdmin() then -- indicate lack of fuel reading
    widget.setText("stardustlib:bottomBar.fuelGauge", "^gray;(not on ship)")
  else -- dismiss if invalid situation!
    if not alreadyOpen then
      pane.playSound("/sfx/interface/clickon_error.ogg")
    end
    pane.dismiss()
    return nil
  end
  
  _update(...)
  if speciesUpdate then speciesUpdate(...) end
end
