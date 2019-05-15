--

require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/lib/stardust/playerext.lua"

view = nil
function nf() end

local trees = { }
function init()
  canvas = widget.bindCanvas("viewCanvas")
  
  do -- load in skill data
    local cfg = root.assetJson("/aetheri/species/skilltree.config")
    local t
    -- recursive function for loading in node data
    local iterateTree iterateTree = function(tree, pfx, offset)
      for k, n in pairs(tree) do
        local type = n.type or "node"
        local pos = vec2.add(n.position or {0, 0}, offset)
        local path = string.format("%s/%s", pfx, k)
        if type == "group" then
          iterateTree(n.children or { }, path, pos)
        else -- actual node
          local node = {
            path = path,
            position = pos,
          }
          t.nodes[path] = node
        end
      end
    end
    
    for name, c in pairs(cfg.trees) do
      t = { nodes = { } }
      trees[name] = t
      iterateTree(c, "", {0, 0})
    end
    
  end
  
  view = nodeView.new(trees.passive)
  redrawCanvas()
end

function update()
  (view and view.update or nf)(view)
  if view.needsRedraw then redrawCanvas() end
end

function redrawCanvas()
  view.needsRedraw = nil
  (view and view.redraw or nf)(view)
end

function canvasClickEvent(pos, btn, down)
  --playerext.message(vec2.print(position, 1))
  (view and view.clickEvent or nf)(view, pos, btn, down)
end

function canvasKeyEvent(key, isDown)
  --[[if key == 65 then
    self.input.up = isDown
  elseif key == 43 then
    self.input.left = isDown
  elseif key == 61 then
    self.input.down = isDown
  elseif key == 46 then
    self.input.right = isDown
  end]]
end





nodeView = { }
nodeView.nodeSpacing = 16

function nodeView.new(...)
  local v = setmetatable({ }, { __index = nodeView })
  v:init(...)
  return v
end

function nodeView:init(tree)
  self.tree = tree
  self.scroll = vec2.mul(widget.getSize("viewCanvas"), 0.5)
end

function nodeView:update()
  self.lastPos = self.lastPos or {0, 0}
  local pos = canvas:mousePosition()
  
  if vec2.mag(vec2.sub(pos, self.lastPos)) > 0 then -- if mouse moved...
    if self.scrolling then
      self.scroll = vec2.add(self.scroll, vec2.sub(pos, self.lastPos))
      self.needsRedraw = true
    end
    
    local hover = self:nodeAt(vec2.sub(pos, self.scroll))
    if self.hover ~= hover then
      self.hover = hover
      self.needsRedraw = true
    end
  end
  
  self.lastPos = pos
end

function nodeView:clickEvent(pos, btn, down)
  -- 0-2: left, middle, right
  if btn == 0 then -- left button
    if down then
      if self.hover then -- click on node
        --
      else self.scrolling = true end -- or scroll
    else self.scrolling = false end
  end
end

function nodeView:redraw()
  canvas:clear()
  --canvas:drawImage("/interface/lockicon.png", self.scroll, 1, {255, 255, 255}, true)
  for _, node in pairs(self.tree.nodes) do
    --canvas:drawText(node.path, { position = vec2.add(self.scroll, vec2.mul(node.position, self.nodeSpacing)), horizontalAnchor = "mid", verticalAnchor = "mid" }, 8)
    canvas:drawImage("/items/currency/essence.png", vec2.add(self.scroll, vec2.mul(node.position, self.nodeSpacing)), 1, {255, 255, 255}, true)
  end
  if self.hover then -- tool tip!
    canvas:drawText(self.hover.path, { position = vec2.add(vec2.add(self.scroll, vec2.mul(self.hover.position, self.nodeSpacing)), {8, 4}), horizontalAnchor = "left", verticalAnchor = "top" }, 8)
  end
end


function nodeView:nodeAt(pos)
  for _, node in pairs(self.tree.nodes) do
    if vec2.mag(vec2.sub(pos, vec2.mul(node.position, self.nodeSpacing))) <= 8 then return node end
  end
  return nil
end
























--
