metagui = metagui or { }
local mg = metagui


do -- asset type definitions
  
  -- common functions between asset types
  local function frameImage(self, frame)
    if type(frame) ~= "table" then frame = { frame or "default" } end
    local t = {self.image, ":"} util.appendLists(t, frame)
    if self.useThemeDirectives then table.insert(t, 4, mg.theme[self.useThemeDirectives]) end
    return table.concat(t)
  end
  
  ----------------------
  -- ninepatch assets --
  ----------------------
  local ninePatchReg = { }
  
  local ninePatch = { }
  local ninePatchMeta = { __index = ninePatch }
  
  -- calculates all points involved in a ninepatch
  local function npMatrix(r, m)
    local h = { r[1], r[1] + m[1], r[3] - m[3], r[3] }
    local v = { r[2], r[2] + m[2], r[4] - m[4], r[4] }
    local res = { { }, { }, { }, { } }
    for y=1,4 do
      for x=1,4 do
        res[y][x] = {h[x], v[y]}
      end
    end
    return res
  end
  
  -- calls the above, then arranges matrix into section rects
  local function npRs(r, m)
    local mx = npMatrix(r, m)
    local res = { }
    for y=1,3 do
      for x=1,3 do
        local bl, tr = mx[y][x], mx[y+1][x+1]
        table.insert(res, { bl[1], bl[2], tr[1], tr[2]})
      end
    end
    return res
  end
  
  -- export
  mg.npMatrix = npMatrix
  mg.npRs = npRs
  
  ninePatch.frameImage = frameImage
  
  function ninePatch:draw(c, f, r) -- canvas, frame, rect
    if not r then
      local s = c:size()
      r = {0, 0, s[1], s[2]}
    end
    local sr = {0, 0, self.frameSize[1], self.frameSize[2]}
    local invm = {self.margins[1], self.margins[4], self.margins[3], self.margins[2]}
    local scm = invm
    if self.isHD then
      scm = { } for k,v in pairs(invm) do scm[k] = v*0.5 end
    end
    local img = self:frameImage(f)
    
    local rc, sc = npRs(r, scm), npRs(sr, invm)
    for i=1,9 do c:drawImageRect(img, sc[i], rc[i]) end
  end
  ninePatch.drawToCanvas = ninePatch.draw -- alias for backwards compatibility
  
  function mg.ninePatch(path)
    -- rectify path input
    path = mg.asset((path:match('^(.*)%..-$') or path) .. ".png")
    path = path:match('^(.*)%..-$') or path
    if ninePatchReg[path] then return ninePatchReg[path] end
    local np = setmetatable({ }, ninePatchMeta) ninePatchReg[path] = np
    np.image = path .. ".png"
    
    local d = root.assetJson(path .. ".frames")
    np.margins = d.ninePatchMargins
    np.frameSize = d.frameGrid.size
    np.isHD = d.isHD
    
    return np
  end
  function mg.isNinePatch(ast) return type(ast) == "table" and getmetatable(ast) == ninePatchMeta end
  
  ---------------------
  -- extended assets --
  ---------------------
  local extAssetReg = { } -- registry
  
  local extAsset = { } -- prototype
  local extAssetMeta = { __index = extAsset }
  
  function extAssetMeta.__tostring(self)
    return self.image
  end
  
  -- if a theme expects a string it'll probably be concatenating; give expected result
  function extAssetMeta.__concat(self, other)
    return self.image .. other
  end
  
  extAsset.frameImage = frameImage
  
  function extAsset:draw(c, f, pos, scale, rot)
    scale = scale or 1
    if self.isHD then scale = scale * 0.5 end
    local img = self:frameImage(f)
    c:drawImageDrawable(img, pos, scale, nil, rot)
  end
  
  function extAsset:drawTiled(c, f, r, offset, scale)
    if not r then
      local s = c:size()
      r = {0, 0, s[1], s[2]}
    end
    offset = offset or {0, 0}
    scale = scale or 1
    if self.isHD then scale = scale * 0.5 end
    local img = self:frameImage(f)
    c:drawTiledImage(img, offset, r, scale)
  end
  
  function mg.extAsset(path)
    path = mg.asset((path:match('^(.*)%..-$') or path) .. ".png")
    path = path:match('^(.*)%..-$') or path
    if extAssetReg[path] then return extAssetReg[path] end
    local ast = setmetatable({ }, extAssetMeta) extAssetReg[path] = ast
    ast.image = path .. ".png"
    
    local res, d = pcall(root.assetJson, path .. ".frames")
    if not res then d = { } end
    ast.frameSize = res and d.frameGrid.size or root.imageSize(ast.image)
    ast.isHD = d.isHD
    
    return ast
  end
  function mg.isExtAsset(ast) return type(ast) == "table" and getmetatable(ast) == extAssetMeta end
end

function mg.measureString(str, wrapWidth, size)
  pane.addWidget({ type = "label", value = str, wrapWidth = wrapWidth, fontSize = size }, "__measure")
  local s = widget.getSize("__measure")
  pane.removeWidget("__measure")
  return s
end

function mg.getColor(c)
  if c == "none" then return nil end
  if c == "accent" then
    if mg.cfg.accentColor == "accent" then return "7f7f7f" end
    return mg.getColor(mg.cfg.accentColor)
  end
  return c
end

function mg.formatText(str)
  if not str then return nil end
  local colorSub = {
    ["^accent;"] = string.format("^#%s;", mg.getColor("accent")),
  }
  str = string.gsub(str, "(%b^;)", colorSub)
  return str
end
