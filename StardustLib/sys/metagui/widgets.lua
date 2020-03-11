local mg = metagui

local widgets = mg.widgetTypes
local mkwidget = mg.mkwidget
local debug = mg.debugFlags

do -- layout
  widgets.layout = mg.proto(mg.widgetBase, {
    -- widget attributes
    isBaseWidget = true,
    expandMode = {1, 0}, -- agree to expand to fill horizontally
    
    -- defaults
    mode = "manual",
    spacing = 2,
  })
  
  -- layout modes:
  -- "manual" (the explicit default) is exactly what it says on the tim
  -- "horizontal" and "vertical" auto-arrange for each axis
  
  function widgets.layout:init(base, param)
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
        elseif type(c) == "number" then mg.createWidget({ type = "spacer", size = math.floor(c) }, self)
        elseif c[1] then mg.createImplicitLayout(c, self) else
          mg.createWidget(c, self)
        end
      end
    end
  end
  
  function widgets.layout:preferredSize()
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
  
  function widgets.layout:updateGeometry(noApply)
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
end do -- spacer
  widgets.spacer = mg.proto(mg.widgetBase, {
    expandMode = {2, 2} -- prefer to expand
  })
  function widgets.spacer:init(base, param)
    if self.explicitSize then expandMode = {0, 0} end -- fixed size
  end
  function widgets.spacer:preferredSize() local p = self.explicitSize or 0 return {p, p} end
end do -- canvas
  widgets.canvas = mg.proto(mg.widgetBase, {
    expandMode = {1, 1} -- can expand if no size specified
  })
  
  function widgets.canvas:init(base, param)
    if self.explicitSize then expandMode = {0, 0} end -- fixed size
    self.backingWidget = mkwidget(base, { type = "canvas" })
  end
  
  function widgets.canvas:preferredSize() return self.explicitSize or {64, 64} end
  function widgets.canvas:isMouseInteractable() return true end
end do -- button
  widgets.button = mg.proto(mg.widgetBase, {
    expandMode = {1, 0}, -- will expand horizontally, but not vertically
  })
  
  function widgets.button:init(base, param)
    self.caption = mg.formatText(param.caption)
    self.captionOffset = param.captionOffset or {0, 0}
    self.color = param.color
    self.state = "idle"
    self.backingWidget = mkwidget(base, { type = "canvas" })
  end
  
  function widgets.button:minSize() return {16, 16} end
  function widgets.button:preferredSize() return self.explicitSize or {64, 16} end
  
  function widgets.button:draw() theme.drawButton(self) end
  
  function widgets.button:isMouseInteractable() return true end
  function widgets.button:onMouseEnter()
    self.state = "hover"
    self:queueRedraw()
    theme.onButtonHover(self)
  end
  function widgets.button:onMouseLeave() self.state = "idle" self:queueRedraw() end
  function widgets.button:onMouseButtonEvent(btn, down)
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
  
  function widgets.button:onClick() end
  
  function widgets.button:setText(t)
    self.caption = mg.formatText(t)
    self:queueRedraw()
    if self.parent then self.parent:queueGeometryUpdate() end
  end
end do -- label
  widgets.label = mg.proto(mg.widgetBase, {
    expandMode = {1, 0}, -- will expand horizontally, but not vertically
    text = "",
  })
  
  function widgets.label:init(base, param)
    self.text = mg.formatText(param.text)
    self.color = param.color
    self.fontSize = param.fontSize
    self.align = param.align
    
    if param.inline then self.expandMode = {0, 0} end
    
    self.backingWidget = mkwidget(base, { type = "canvas" })
  end
  
  function widgets.label:preferredSize(width)
    if self.explicitSize then return self.explicitSize end
    return mg.measureString(self.text, width, self.fontSize)
  end
  
  function widgets.label:draw()
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
  
  function widgets.label:setText(t)
    self.text = mg.formatText(t)
    self:queueRedraw()
    if self.parent then self.parent:queueGeometryUpdate() end
  end
end do -- image
  widgets.image = mg.proto(mg.widgetBase, {
    file = "/assetmissing.png", -- fallback file
  })
  
  function widgets.image:init(base, param)
    self.file = mg.path(param.file)
    self.backingWidget = mkwidget(base, { type = "canvas" })
  end
  function widgets.image:preferredSize() return root.imageSize(self.file) end
  function widgets.image:draw()
    local c = widget.bindCanvas(self.backingWidget)
    c:clear() c:drawImage(self.file, {0, 0})
  end
  function widgets.image:setFile(f)
    self.file = mg.path(f)
    if parent then parent:queueGeometryUpdate() end
  end
end do -- item slot
  widgets.itemSlot = mg.proto(mg.widgetBase, {
    --
  })
  
  function widgets.itemSlot:init(base, param)
    self.glyph = mg.path(param.glyph or param.colorGlyph)
    self.colorGlyph = not not param.colorGlyph -- some themes may want to render non-color glyphs as monochrome in their own colors
    self.color = param.color -- might as well let themes have at this
    self.autoInteract = param.autoInteract or param.auto
    --
    self.backingWidget = mkwidget(base, { type = "canvas" })
    self.subWidgets = {
      slot = mkwidget(base, { type = "itemslot", callback = "_clickLeft", rightClickCallback = "_clickRight", showRarity = false })
    }
    if param.item then self:setItem(param.item) end
  end
  function widgets.itemSlot:preferredSize() return {18, 18} end
  function widgets.itemSlot:applyGeometry()
    mg.widgetBase.applyGeometry(self) -- base first
    widget.setPosition(self.subWidgets.slot, widget.getPosition(self.backingWidget)) -- sync position
    widget.setSize(self.subWidgets.slot, {18, 18})
  end
  function widgets.itemSlot:draw()
    theme.drawItemSlot(self)
  end
  
  function widgets.itemSlot:isMouseInteractable() return true end
  function widgets.itemSlot:onMouseEnter() self.hover = true self:queueRedraw() end
  function widgets.itemSlot:onMouseLeave() self.hover = false self:queueRedraw() end
  function widgets.itemSlot:onMouseButtonEvent(btn, down)
    --pane.playSound("/sfx/interface/clickon_success.ogg", 0, 1.0)
  end
  
  function widgets.itemSlot:item() return widget.itemSlotItem(self.subWidgets.slot) end
  function widgets.itemSlot:setItem(itm)
    local old = self:item()
    widget.setItemSlotItem(self.subWidgets.slot, itm)
    self:queueRedraw()
    return old
  end
end do -- item grid
  widgets.itemGrid = mg.proto(mg.widgetBase, {
    -- widget attributes
    isBaseWidget = true,
    
    -- defaults
    spacing = 2,
  })
  
  function widgets.itemGrid:init(base, param)
    self.children = self.children or { } -- always have a children table
    
    self.columns = param.columns
    self.spacing = param.spacing
    if type(self.spacing) == "number" then self.spacing = {self.spacing, self.spacing} end
    self.autoInteract = param.autoInteract or param.auto
    
    self.backingWidget = mkwidget(base, { type = "layout", layoutType = "basic" })
    
    local slots = param.slots or 1
    for i=1,slots do self:addSlot() end
  end
  
  function widgets.itemGrid:addSlot(item)
    self:addChild {
      type = "itemSlot",
      autoInteract = self.autoInteract,
      item = item,
    }
  end
  function widgets.itemGrid:removeSlot(index) if self.children[index] then self.children[index]:delete() end end
  function widgets.itemGrid:slot(index) return self.children[index] end
  
  function widgets.itemGrid:item(index) if not self:slot(index) then return nil end return self:slot(index):item() end
  function widgets.itemGrid:setItem(index, item) if not self:slot(index) then return nil end return self:slot(index):setItem(item) end
  
  function widgets.itemGrid:preferredSize(width)
    local dim = {0, 0}
    
    if self.columns then dim[1] = self.columns else
      width = width + self.spacing[1]
      local sw = 18 + self.spacing[1]
      dim[1] = math.modf(width / sw)
    end
    
    local w, p = math.modf(#(self.children) / dim[1])
    dim[2] = w + math.ceil(p)
    
    return {dim[1] * 18 + self.spacing[1] * (dim[1] - 1), dim[2] * 18 + self.spacing[2] * (dim[2] - 1)}
  end
  
  function widgets.itemGrid:updateGeometry()
    local slots = #(self.children)
    local cols = math.modf((self.size[1] + self.spacing[1]) / (18 + self.spacing[1]))
    for i, s in pairs(self.children) do
      s.index = i -- shove this in for script use
      local row = math.modf((i-1) / cols)
      local col = i - 1 - (row*cols)
      s.position = {(18 + self.spacing[1]) * col, (18 + self.spacing[2]) * row}
    end
    self:applyGeometry()
  end
end
