--

require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/lib/stardust/playerext.lua"

view = nil
function nf() end

local function resolvePath(path, pfx)
  if path:sub(1, 1) == "/" then return path
  else return string.format("%s/%s", pfx, path) end
end

local function numStr(n) -- friendly string representation of number
  local fn = math.floor(n)
  if fn == n then return tostring(fn) else return tostring(n) end
end

local function setNodeVisuals(node)
  local tt = { }
  if node.name then table.insert(tt, string.format("^violet;%s^reset;\n", node.name)) end
  for _, g in pairs(node.grants or { }) do
    local mode, stat, amt = table.unpack(g)
    if mode == "flat" then
      table.insert(tt, string.format("+^white;%s ^cyan;%s^reset;\n", numStr(amt), statNames[stat] or stat))
    elseif mode == "increased" then
      table.insert(tt, string.format("^white;%s%%^reset; increased ^cyan;%s^reset;\n", numStr(amt*100), statNames[stat] or stat))
    elseif mode == "more" then
      table.insert(tt, string.format("^white;%s%%^reset; more ^cyan;%s^reset;\n", numStr(amt*100), statNames[stat] or stat))
    end
  end
  node.toolTip = table.concat(tt)
end

local trees = { }
function init()
  canvas = widget.bindCanvas("viewCanvas")
  
  do -- load in skill data
    local cfg = root.assetJson("/aetheri/species/skilltree.config")
    -- global stuffs
    compatId = cfg.compatId
    statNames = cfg.statNames
    baseStats = cfg.baseStats
    
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
            name = n.name,
            grants = n.grants,
          }
          t.nodes[path] = node
          setNodeVisuals(node)
          if n.connectsTo then -- premake connections
            for _, cn in pairs(n.connectsTo) do
              local p1, p2 = path, resolvePath(cn, pfx)
              if p1 > p2 then p1, p2 = p2, p1 end -- sort
              t._conn[string.format("%s+%s", p1, p2)] = {p1, p2}
            end
          end
        end
      end
    end
    
    for name, c in pairs(cfg.trees) do
      t = { name = name, nodes = { }, _conn = { }, connections = { } }
      trees[name] = t
      iterateTree(c, "", {0, 0})
      for k, v in pairs(t._conn) do
        local n1, n2 = t.nodes[v[1]], t.nodes[v[2]]
        if n1 and n2 then
          sb.logInfo("connection: " .. util.tableToString(v))
          t.connections[k] = {n1, n2}
        end
      end t._conn = nil -- and clear temporary data
    end
    
  end
  
  loadPlayerData()
  
  view = nodeView.new(trees.passive)
  redrawCanvas()
end

function loadPlayerData()
  playerData = status.statusProperty("aetheri:skillTreeData", nil)
  if not playerData or playerData.compatId ~= compatId then
    -- reset data
    if playerData then
      -- TODO: give back AP - playerData.spentAP
    end
    playerData = {
      compatId = compatId,
      nodesUnlocked = { }
    }
    status.setStatusProperty("aetheri:skillTreeData", playerData) -- and save back
  end
  
  for _, t in pairs(trees) do
    playerData.nodesUnlocked[t.name] = playerData.nodesUnlocked[t.name] or { }
    playerData.nodesUnlocked[t.name]["/origin"] = true
  end
  
  recalculateStats()
  -- refresh view on reload
  if view then view.needsRedraw = true end
end

function recalculateStats()
  --playerData.calculatedStats = { }
  local stats = { }
  for stat, t in pairs(baseStats) do -- populate base stat values
    stats[stat] = {t[1] or 0, t[2] or 1, t[3] or 1}
  end
  
  for tn, lst in pairs(playerData.nodesUnlocked) do
    for path, f in pairs(lst) do
      if f then
        local node = trees[tn].nodes[path]
        for _, g in pairs(node.grants or { }) do
          local mode, stat, amt = table.unpack(g)
          if mode == "flat" and stats[stat] then stats[stat][1] = stats[stat][1] + amt
          elseif mode == "increased" and stats[stat] then stats[stat][2] = stats[stat][2] + amt
          elseif mode == "more" and stats[stat] then stats[stat][3] = stats[stat][3] * (1.0 + amt)
          end --
        end
      end
    end
  end
  
  playerData.calculatedStats = stats
end

function commitPlayerData()
  recalculateStats()
  status.setStatusProperty("aetheri:skillTreeData", playerData)
  world.sendEntityMessage(player.id(), "aetheri:refreshStats")
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
        -- TEMP
        playerData.nodesUnlocked[self.tree.name][self.hover.path] = not playerData.nodesUnlocked[self.tree.name][self.hover.path] or nil
        commitPlayerData()
        self.needsRedraw = true
      else self.scrolling = true end -- or scroll
    else self.scrolling = false end
  end
end

function nodeView:redraw()
  canvas:clear()
  --canvas:drawImage("/interface/lockicon.png", self.scroll, 1, {255, 255, 255}, true)
  local lco = {-.5, -.5}
  local lineColors = {
    {127, 63, 63, 63},
    {127, 127, 255, 127},
    {255, 255, 255, 127},
  }
  for _, c in pairs(self.tree.connections) do -- draw connection lines
    --sb.logInfo(string.format("drawing line \"%s\" between %s and %s", _, c[1].path, c[2].path))
    local lc = 1
    if self:isNodeUnlocked(c[1]) then lc = lc + 1 end
    if self:isNodeUnlocked(c[2]) then lc = lc + 1 end
    canvas:drawLine(vec2.add(self:nodeDrawPos(c[1]), lco), vec2.add(self:nodeDrawPos(c[2]), lco), lineColors[lc], 2)
  end
  
  for _, node in pairs(self.tree.nodes) do
    --canvas:drawText(node.path, { position = vec2.add(self.scroll, vec2.mul(node.position, self.nodeSpacing)), horizontalAnchor = "mid", verticalAnchor = "mid" }, 8)
    canvas:drawImage("/items/currency/essence.png", self:nodeDrawPos(node), 1, self:isNodeUnlocked(node) and {255, 255, 255} or {127, 127, 127}, true)
  end
  if self.hover then -- tool tip!
    canvas:drawText(self.hover.toolTip, { position = vec2.add(self:nodeDrawPos(self.hover), {12, 4}), horizontalAnchor = "left", verticalAnchor = "top" }, 8, {191, 191, 191})
  end
end

function nodeView:isNodeUnlocked(node)
  return playerData.nodesUnlocked[self.tree.name][node.path]
end

function nodeView:nodeDrawPos(node)
  return vec2.add(self.scroll, vec2.mul(node.position, self.nodeSpacing))
end

function nodeView:nodeAt(pos)
  for _, node in pairs(self.tree.nodes) do
    if vec2.mag(vec2.sub(pos, vec2.mul(node.position, self.nodeSpacing))) <= 8 then return node end
  end
  return nil
end
























--
