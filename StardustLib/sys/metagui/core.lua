require "/scripts/util.lua"
require "/scripts/vec2.lua"

local debug = {
  --showLayoutBoxes = true,
}

-- metaGUI core
metagui = metagui or { }
local mg = metagui

require "/sys/metagui/gfx.lua"

do -- encapsulate
  local id = 0
  function mg.newUniqueId()
    id = id + 1
    return tostring(id)
  end
end

local function mkwidget(parent, param)
  local id = mg.newUniqueId()
  if not parent then
    pane.addWidget(param, id)
    return id
  end
  widget.addChild(parent, param, id)
  return table.concat{ parent, '.', id }
end

local proto, getproto do
  local pt = { }
  getproto = function(parent)
    if not pt[parent] then
      pt[parent] = { __index = parent }
    end
    return pt[parent]
  end
  proto = function(parent, table) return setmetatable(table or { }, getproto(parent)) end
end

local widgetTypes = { }
local widgetBase = {
  expandMode = {0, 0}, -- default: decline to expand in either direction (1 is "can", 2 is "wants to")
}
local redrawQueue = { }

function widgetBase:minSize() return {0, 0} end
function widgetBase:preferredSize() return {0, 0} end

function widgetBase:init() end

function widgetBase:queueRedraw() redrawQueue[self] = true end
function widgetBase:draw() end

function widgetBase:applyGeometry()
  self.size = self.size or self:preferredSize() -- fill in default size if absent
  local tp = self.position or {0, 0}
  local s = self
  while s.parent and not s.parent.isBaseWidget do
    tp = vec2.add(tp, s.parent.position or {0, 0})
    s = s.parent
  end
  s = s.parent -- we want the parent of the result
  -- apply calculated total position
  --sb.logInfo("processing " .. (self.backingWidget or "unknown") .. ", type " .. self.typeName)
  local etp
  if self.parent then etp = { tp[1], s.size[2] - (tp[2] + self.size[2]) } else etp = tp end -- if no parent, it must be a backing widget
  if self.backingWidget then
    widget.setSize(self.backingWidget, {math.floor(self.size[1]), math.floor(self.size[2])})
    widget.setPosition(self.backingWidget, {math.floor(etp[1]), math.floor(etp[2])})
  end
  --sb.logInfo("widget " .. (self.backingWidget or "unknown") .. ", type " .. self.typeName .. ", pos (" .. self.position[1] .. ", " .. self.position[2] .. "), size (" .. self.size[1] .. ", " .. self.size[2] .. ")")
  self:queueRedraw()
  if self.children then
    for k,c in pairs(self.children) do
      if c.applyGeometry then c:applyGeometry() end
    end
  end
end

function widgetBase:updateGeometry()
  
end

function widgetBase:addChild(param) return mg.createWidget(param, self) end

do -- layout
  widgetTypes.layout = proto(widgetBase, {
    -- widget attributes
    isBaseWidget = true,
    expandMode = {1, 0}, -- agree to expand to fill horizontally
    
    -- defaults
    mode = "manual",
    spacing = 2,
  })
  
  -- layout engine is probably going to need to be a multi-dive kind of deal
  -- minimums first (inside out), then calculate actual sizes outside-in
  -- multiple layout modes... hmm.
  -- "manual" (the explicit default) is exactly what it says on the tim
  -- "horizontal" and "vertical" auto-arrange for each axis
  
  function widgetTypes.layout:init(base, param)
    self.children = self.children or { } -- always have a children table
    
    -- parameters first
    self.mode = param.mode
    if self.mode == "h" then self.mode = "horizontal" end
    if self.mode == "v" then self.mode = "vertical" end
    self.spacing = param.spacing
    self.expandMode = param.expandMode
    
    self.backingWidget = mkwidget(base, { type = "layout", layoutType = "basic", zlevel = param.zLevel })
    if debug.showLayoutBoxes then -- image to make it visible (random color)
      widget.addChild(self.backingWidget, { type = "image", file = string.format("/assetmissing.png?crop=0;0;1;1?multiply=0000?replace;0000=%06x4f", sb.makeRandomSource():randu32() % 0x1000000), scale = 1024 })
    end
    if type(param.children) == "table" then -- iterate through and add children
      for _, c in pairs(param.children) do
        if type(c) == "string" then
          if c == "spacer" then
            mg.createWidget({ type = "spacer" }, self)
          end
        elseif c[1] then mg.createImplicitLayout(c, self) else
          mg.createWidget(c, self)
        end
      end
    end
  end
  
  function widgetTypes.layout:preferredSize()
    local res = {0, 0}
    if self.mode == "horizontal" or self.mode == "vertical" then
      local axis = self.mode == "vertical" and 2 or 1
      local opp = 3 - axis
      
      res[axis] = self.spacing * (#(self.children) - 1)
      
      for _, c in pairs(self.children) do
        local ps = c:preferredSize()
        res[opp] = math.max(res[opp], ps[opp])
        res[axis] = res[axis] + ps[axis]
      end
    end
    return res
  end
  
  function widgetTypes.layout:updateGeometry(noApply)
    -- autoarrange modes
    if self.mode == "horizontal" or self.mode == "vertical" then
      local axis = self.mode == "vertical" and 2 or 1
      local opp = 3 - axis
      
      -- find maximum expansion level
      -- if not zero, anything that matches it gets expanded to equal size after preferred sizes are fulfilled
      local exLv = 0
      for _, c in pairs(self.children) do if c.expandMode[axis] > exLv then exLv = c.expandMode[axis] end end
      local numEx = 0 -- count matching
      for _, c in pairs(self.children) do if c.expandMode[axis] == exLv then numEx = numEx + 1 end end
      
      local sizeAcc = self.spacing * (#(self.children) - 1)
      -- size pass 1
      for _, c in pairs(self.children) do
        if exLv == 0 or c.expandMode[axis] < exLv then
          c.size = c:preferredSize()
          sizeAcc = sizeAcc + c.size[axis]
        end
        -- ...
      end
      -- and 2
      if exLv > 0 then
        local sz = (self.size[axis] - sizeAcc) / numEx
        local szf = math.floor(sz)
        local rm = 0
        for _, c in pairs(self.children) do
          if c.expandMode[axis] == exLv then
            -- do a remainder-accumulator to keep things integer
            rm = rm + (sz - szf)
            local rmf = math.floor(rm)
            c.size = c:preferredSize()
            c.size[axis] = szf + rmf
            rm = rm - rmf
          end
        end
      end
      
      -- and position
      local posAcc = 0
      for _, c in pairs(self.children) do
        c.position = c.position or {0, 0}
        c.position[axis] = posAcc
        posAcc = posAcc + c.size[axis] + self.spacing
        -- resize or align on opposite axis
        if c.expandMode[opp] >= 1 then
          c.size[opp] = self.size[opp]
        else
          c.position[opp] = math.floor(self.size[opp]/2 - c.size[opp]/2)
        end
      end
      
    end
    
    -- propagate
    if not noApply then for _, c in pairs(self.children or { }) do c:updateGeometry(true) end end
    -- finally, apply
    self:applyGeometry()
  end
end

do -- spacer
  widgetTypes.spacer = proto(widgetBase, {
    expandMode = {2, 2} -- prefer to expand
  })
end

do -- button
  widgetTypes.button = proto(widgetBase, {
    expandMode = {1, 0}, -- will expand horizontally, but not vertically
  })
  
  function widgetTypes.button:init(base, param)
    self.caption = param.caption or ""
    self.backingWidget = mkwidget(base, { type = "canvas", })
  end
  
  function widgetTypes.button:minSize() return {16, 16} end
  function widgetTypes.button:preferredSize() return self.explicitSize or {64, 16} end
  
  function widgetTypes.button:draw() theme.drawButton(self) end
end

-- DEBUG populate type names
for id, t in pairs(widgetTypes) do t.typeName = id end

function mg.createWidget(param, parent)
  if not param or not param.type or not widgetTypes[param.type] then return nil end -- abort if not valid
  local w = proto(widgetTypes[param.type])
  if parent then -- add as child
    w.parent = parent
    w.parent.children = w.parent.children or { }
    table.insert(w.parent.children, w)
  end
  
  -- some basics
  w.position = param.position
  w.explicitSize = param.size
  w.size = param.size
  
  local base
  if parent then -- find base widget
    local f = parent
    while not f.isBaseWidget and f.parent do f = f.parent end
    base = f.backingWidget
  end
  w:init(base, param)
  return w
end

function mg.createImplicitLayout(list, parent, defaults)
  local p = { type = "layout", children = list }
  if parent then -- inherit some defaults off parent
    if parent.mode == "horizontal" then p.mode = "vertical"
    elseif parent.mode == "vertical" then p.mode = "horizontal" end
    p.spacing = parent.spacing
  end
  
  if defaults then util.mergeTable(p, defaults) end
  if type(list[1]) == "table" and not list[1][1] and not list[1].type then util.mergeTable(p, list[1]) end
  return mg.createWidget(p, parent)
end





function init() init = nil -- clear out for prep
  for k,v in pairs(player) do
    sb.logInfo(k .. " (" .. type(v) .. ")")
  end
  
  mg.cfg = config.getParameter("___") -- window config
  
  mg.theme = root.assetJson(mg.cfg.themePath .. "theme.json")
  mg.theme.id = mg.cfg.theme
  mg.theme.path = mg.cfg.themePath
  _ENV.theme = mg.theme -- alias
  require(mg.theme.path .. "theme.lua") -- load in theme
  
  -- TODO set up some parameter stuff?? idk, maybe the theme does most of that
  
  -- set up basic pane stuff
  local borderMargins = mg.theme.metrics.borderMargins[mg.cfg.style]
  --[[pane.addWidget({
    type = "layout", zlevel = -9999, size = mg.cfg.totalSize, position = {0, 0}, layoutType = "basic"
  }, "frame")
  pane.addWidget({
    type = "layout", size = mg.cfg.size, position = {borderMargins[1], borderMargins[4]}, layoutType = "basic"
  }, "layout")]]
  frame = mg.createWidget({ type = "layout", size = mg.cfg.totalSize, position = {0, 0}, zlevel = -9999 })
  paneBase = mg.createImplicitLayout(mg.cfg.children, nil, { size = mg.cfg.size, position = {borderMargins[1], borderMargins[4]}, mode = mg.cfg.layoutMode or "vertical" })
  
  mg.theme.decorate()
  
  frame:updateGeometry()
  paneBase:updateGeometry()
  
  for _, s in pairs(mg.cfg.scripts or { }) do require(s) end
  if init then init() end -- call script init
  
  --[[setmetatable(_ENV, {__index = function(t, k)
    sb.logInfo("absent var: " .. k)
  end})]]
end

local function findWindowPosition()
  if not mg.windowPosition then mg.windowPosition = {0, 0} end -- at the very least, make sure this exists
  local fp
  local sz = mg.cfg.totalSize
  local max = {1920, 1080} -- technically probably 4k
  
  local ws = frame.backingWidget -- widget to search for
  
  -- initial find
  for y=0,max[2],sz[2] do
    for x=0,max[1],sz[1] do
      if widget.inMember(ws, {x, y}) then
        fp = {x, y} break
      end
    end
    if fp then break end
  end
  
  if not fp then return nil end -- ???
  
  local isearch = 32
  -- narrow x
  local search = isearch
  while search >= 1 do
    while widget.inMember(ws, {fp[1] - search, fp[2]}) do fp[1] = fp[1] - search end
    search = search / 2
  end
  
  -- narrow y
  local search = isearch
  while search >= 1 do
    while widget.inMember(ws, {fp[1], fp[2] - search}) do fp[2] = fp[2] - search end
    search = search / 2
  end
  
  mg.windowPosition = fp
end

function update()
  local ws = frame.backingWidget
  if not mg.windowPosition then
    findWindowPosition()
  else
    --local fcp = {mg.windowPosition[1] + mg.cfg.totalSize[1], mg.windowPosition[2] + mg.cfg.totalSize[2]}
    if not widget.inMember(ws, mg.windowPosition) or not widget.inMember(ws, vec2.add(mg.windowPosition, mg.cfg.totalSize)) then findWindowPosition() end
  end
  
  --[[local c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  widget.setText("debugWidget", table.concat {
    "window pos: ", mg.windowPosition[1], ", ", mg.windowPosition[2], "\n",
    "over widget: ", widget.getChildAt(vec2.add(mg.windowPosition, c:mousePosition())) or "none",
  })]]
  
  for w in pairs(redrawQueue) do w:draw() end
  redrawQueue = { }
end

function canvasTest()
  local m = getmetatable('')
  if m.testSvc then m.testSvc.message(nil, nil, "clicked") end
end
