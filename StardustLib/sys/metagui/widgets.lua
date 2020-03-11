local mg = metagui

local widgetTypes = mg.widgetTypes
local mkwidget = mg.mkwidget
local debug = mg.debugFlags

do -- layout
  widgetTypes.layout = mg.proto(mg.widgetBase, {
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
    
    if type(self.explicitSize) == "number" then
      --self.explicitSize = {self.explicitSize, self.explicitSize}
      if self.mode == "horizontal" then self.expandMode = {1, 0} end
      if self.mode == "vertical" then self.expandMode = {0, 1} end
    end
    
    self.expandMode = param.expandMode or self.expandMode
    
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
      if type(self.explicitSize) == "number" then res[opp] = self.explicitSize end
    elseif self.mode == "manual" then
      if self.explicitSize then return self.explicitSize end
      for _, c in pairs(self.children) do
        local fc = vec2.add(c.position, c:preferredSize())
        res[1] = math.max(res[1], fc[1])
        res[2] = math.max(res[2], fc[2])
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
          c.size = c:preferredSize(axis == 2 and self.size[1] or nil)
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
            c.size = c:preferredSize(axis == 1 and szf+rmf or self.size[1])
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
          c.size[opp] = math.min(c.size[opp], self.size[opp]) -- force fit regardless
          c.position[opp] = math.floor(self.size[opp]/2 - c.size[opp]/2)
        end
      end
      
    end
    
    -- propagate
    for _, c in pairs(self.children or { }) do c:updateGeometry(true) end
    -- finally, apply
    if not noApply then self:applyGeometry() end
  end
end

do -- spacer
  widgetTypes.spacer = mg.proto(mg.widgetBase, {
    expandMode = {2, 2} -- prefer to expand
  })
end

do -- button
  widgetTypes.button = mg.proto(mg.widgetBase, {
    expandMode = {1, 0}, -- will expand horizontally, but not vertically
  })
  
  function widgetTypes.button:init(base, param)
    self.caption = mg.formatText(param.caption)
    self.captionOffset = param.captionOffset or {0, 0}
    self.color = param.color
    self.state = "idle"
    self.backingWidget = mkwidget(base, { type = "canvas" })
  end
  
  function widgetTypes.button:minSize() return {16, 16} end
  function widgetTypes.button:preferredSize() return self.explicitSize or {64, 16} end
  
  function widgetTypes.button:draw() theme.drawButton(self) end
  
  function widgetTypes.button:isMouseInteractable() return true end
  function widgetTypes.button:onMouseEnter()
    self.state = "hover"
    self:queueRedraw()
    theme.onButtonHover(self)
  end
  function widgetTypes.button:onMouseLeave() self.state = "idle" self:queueRedraw() end
  function widgetTypes.button:onMouseButtonEvent(btn, down)
    if btn == 0 then -- left button
      if down then
        self.state = "press"
        self:queueRedraw()
        theme.onButtonClick(self)
      elseif self.state == "press" then
        self.state = "hover"
        self:queueRedraw()
        mg.startEvent(self.onClick, self)
      end
    end
  end
  
  function widgetTypes.button:onClick() end
  
  function widgetTypes.button:setText(t)
    self.caption = mg.formatText(t)
    self:queueRedraw()
    if self.parent then self.parent:queueGeometryUpdate() end
  end
end

do -- label
  widgetTypes.label = mg.proto(mg.widgetBase, {
    expandMode = {1, 0}, -- will expand horizontally, but not vertically
    text = "",
  })
  
  function widgetTypes.label:init(base, param)
    self.text = mg.formatText(param.text)
    self.color = param.color
    self.fontSize = param.fontSize
    self.align = param.align
    
    if param.inline then self.expandMode = {0, 0} end
    
    self.backingWidget = mkwidget(base, { type = "canvas" })
  end
  
  function widgetTypes.label:preferredSize(width)
    if self.explicitSize then return self.explicitSize end
    return mg.measureString(self.text, width, self.fontSize)
  end
  
  function widgetTypes.label:draw()
    local c = widget.bindCanvas(self.backingWidget) c:clear()
    local pos, ha = {0, self.size[2]}, "left"
    if self.align == "center" or self.align == "mid" then
      pos[1], ha = self.size[1] / 2, "mid"
    elseif self.align == "right" then
      pos[1], ha = self.size[1], "right"
    end
    local color = mg.getColor(self.color) or mg.getColor(theme.baseTextColor)
    if color then color = '#' .. color end
    c:drawText(self.text, { position = pos, horizontalAnchor = ha, verticalAnchor = "top", wrapWidth = self.size[1] + 1 }, self.fontSize or 8, color)
  end
  
  function widgetTypes.label:setText(t)
    self.text = mg.formatText(t)
    self:queueRedraw()
    if self.parent then self.parent:queueGeometryUpdate() end
  end
end
