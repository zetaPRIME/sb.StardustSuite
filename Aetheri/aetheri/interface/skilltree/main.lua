-- Aethyrium - skill tree(s) for the Aetheri

-- TODO: decorations, raw status nodes

require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"

sounds = {
  unlock = "/sfx/objects/ancientenergy_chord.ogg",
  cantUnlock = "/sfx/interface/clickon_error.ogg",
  confirm = "/sfx/objects/essencechest_open3.ogg",
  cancel = "/sfx/interface/nav_insufficient_fuel.ogg",
}

directives = {
  nodeActive = "",
  nodeInactive = "",
}

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

local function tableCount(t)
  local c = 0
  for _, v in pairs(t) do if v then c = c + 1 end end
  return c
end

local function setNodeVisuals(node)
  -- icon
  if not node.icon then
    if node.type == "origin" then
      node.icon = "book.png"
    else
      node.icon = "misc1.png"
    end
  end node.icon = util.absolutePath("/aetheri/interface/skilltree/icons/", node.icon)
  
  -- tool tip
  local tt = { }
  if node.name then table.insert(tt, string.format("^violet;%s^reset;\n", node.name)) end
  for _, g in pairs(node.grants or { }) do
    local mode, stat, amt = table.unpack(g)
    if mode == "description" then
      table.insert(tt, string.format("%s^reset;\n", stat))
    elseif mode == "flat" then
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
    baseNodeCost = cfg.baseNodeCost
    
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
            tree = t, path = path, type = type,
            position = pos, connections = { },
            name = n.name, icon = n.icon,
            grants = n.grants,
            fixedCost = n.fixedCost, costMult = n.costMult,
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
          --sb.logInfo("connection: " .. util.tableToString(v))
          t.connections[k] = {n1, n2}
          n1.connections[n2] = true
          n2.connections[n1] = true
        end
      end t._conn = nil -- and clear temporary data
    end
    
  end
  
  loadPlayerData()
  
  view = nodeView.new(trees.passive)
  redrawCanvas()
end

function loadPlayerData()
  local reset = false
  playerTmpData = {
    apToSpend = 0
  }
  playerData = status.statusProperty("aetheri:skillTreeData", nil)
  if not playerData or playerData.compatId ~= compatId then
    -- reset data
    if playerData then
      -- refund all spent AP
      status.setStatusProperty("aetheri:AP", status.statusProperty("aetheri:AP", 0) + (playerData.spentAP or 0))
    end
    playerData = {
      compatId = compatId,
      spentAP = 0,
      nodesUnlocked = { }
    }
    reset = true
    --status.setStatusProperty("aetheri:skillTreeData", playerData) -- and save back
  end
  playerData.spentAP = playerData.spentAP or 0
  
  for _, t in pairs(trees) do
    playerData.nodesUnlocked[t.name] = playerData.nodesUnlocked[t.name] or { }
  end
  
  recalculateStats()
  
  -- grab visuals
  appearance = status.statusProperty("aetheri:appearance", { })
  directives.nodeActive = string.format("?border=1;%s;00000000", color.toHex(color.fromHsl{ appearance.coreHsl[1], appearance.coreHsl[2], 0.75, 0.75 }))
  
  -- refresh view on reload
  if view then view.needsRedraw = true end
  if reset then commitPlayerData() end
end

function recalculateStats()
  --playerData.calculatedStats = { }
  local stats = { }
  for stat, t in pairs(baseStats) do -- populate base stat values
    stats[stat] = {t[1] or 0, t[2] or 1, t[3] or 1}
  end
  
  playerData.numNodesTaken = { }
  for tn, lst in pairs(playerData.nodesUnlocked) do
    local count = 0
    for path, f in pairs(lst) do
      if f then
        local node = trees[tn].nodes[path]
        if node.type ~= "origin" then count = count + 1 end
        for _, g in pairs(node.grants or { }) do
          local mode, stat, amt = table.unpack(g)
          if mode == "flat" and stats[stat] then stats[stat][1] = stats[stat][1] + amt
          elseif mode == "increased" and stats[stat] then stats[stat][2] = stats[stat][2] + amt
          elseif mode == "more" and stats[stat] then stats[stat][3] = stats[stat][3] * (1.0 + amt)
          end --
        end
      end
    end
    playerData.numNodesTaken[tn] = count
  end
  
  playerData.calculatedStats = stats
end

function commitPlayerData()
  recalculateStats()
  status.setStatusProperty("aetheri:skillTreeData", playerData)
  status.setStatusProperty("aetheri:AP", status.statusProperty("aetheri:AP", 0) - playerTmpData.apToSpend)
  playerTmpData.apToSpend = 0
  world.sendEntityMessage(player.id(), "aetheri:refreshStats")
end

function currentAP()
  return status.statusProperty("aetheri:AP", 0) - playerTmpData.apToSpend
end

function nodeCost(node)
  if node.fixedCost then return node.fixedCost end
  local c = playerData.numNodesTaken[node.tree.name] or 0
  return math.floor(0.5 + baseNodeCost * 2^(c/10) * (node.costMult or 1.0)) -- first node at 2500
end

function isNodeUnlocked(node)
  if node.type == "origin" then return true end
  return not not playerData.nodesUnlocked[node.tree.name][node.path]
end

function canUnlockNode(node)
  if isNodeUnlocked(node) then return false end -- already unlocked
  local connected = false
  for c in pairs(node.connections) do
    if isNodeUnlocked(c) then
      connected = true
      break
    end
  end
  if not connected then return false end
  return currentAP() >= nodeCost(node)
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

function btnConfirm()
  commitPlayerData()
  pane.playSound(sounds.confirm)
end
function btnCancel()
  loadPlayerData()
  pane.playSound(sounds.cancel)
end





nodeView = { }
nodeView.nodeSpacing = 20

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
        -- try to unlock node
        local cost = nodeCost(self.hover)
        if canUnlockNode(self.hover) then
          playerData.nodesUnlocked[self.tree.name][self.hover.path] = true
          playerTmpData.apToSpend = playerTmpData.apToSpend + cost
          recalculateStats()
          self.needsRedraw = true
          pane.playSound(sounds.unlock)
        elseif not isNodeUnlocked(self.hover) then
          pane.playSound(sounds.cantUnlock)
        end
      else self.scrolling = true end -- or scroll
    else self.scrolling = false end
  end
end

local border = {
  {-1, 0},
  {1, 0},
  {0, -1},
  {0, 1},
}
function nodeView:redraw()
  canvas:clear()
  --canvas:drawImage("/interface/lockicon.png", self.scroll, 1, {255, 255, 255}, true)
  local lco = {0, 0}--{-.5, -.5}
  local lineColors = {
    {127, 63, 63, 63},
    {127, 127, 255, 127},
    {255, 255, 255, 127},
  }
  for _, c in pairs(self.tree.connections) do -- draw connection lines
    --sb.logInfo(string.format("drawing line \"%s\" between %s and %s", _, c[1].path, c[2].path))
    local lc = 1
    if isNodeUnlocked(c[1]) then lc = lc + 1 end
    if isNodeUnlocked(c[2]) then lc = lc + 1 end
    canvas:drawLine(vec2.add(self:nodeDrawPos(c[1]), lco), vec2.add(self:nodeDrawPos(c[2]), lco), lineColors[lc], 2)
  end
  
  for _, node in pairs(self.tree.nodes) do
    local pos = self:nodeDrawPos(node)
    local active = isNodeUnlocked(node)
    local nodeDirectives = active and directives.nodeActive or directives.nodeInactive
    --canvas:drawImage("/aetheri/interface/skilltree/nodeBG.png:" .. (active and "active" or "inactive"), pos, 1, {255, 255, 255}, true)
    canvas:drawImage(node.icon .. nodeDirectives, pos, 1, active and {255, 255, 255} or {191, 191, 191}, true)
  end
  if self.hover then -- tool tip!
    local ttPos = vec2.add(self:nodeDrawPos(self.hover), {12, 4})
    local tt = self.hover.toolTip
    if not isNodeUnlocked(self.hover) then tt = string.format("%sCost: ^white;%d ^violet;AP^reset;", tt, nodeCost(self.hover)) end
    local btt = tt:gsub("(%b^;)", "") -- strip codes for border
    for _, off in pairs(border) do
      canvas:drawText(btt, { position = vec2.add(ttPos, off), horizontalAnchor = "left", verticalAnchor = "top" }, 8, {0, 0, 0, 222})
    end
    canvas:drawText(tt, { position = ttPos, horizontalAnchor = "left", verticalAnchor = "top" }, 8, {191, 191, 191})
  end
  
  canvas:drawText(
    string.format("^white;%d ^violet;AP^reset;", math.floor(currentAP())),
    { position = {480.0, 506.0}, horizontalAnchor = "mid", verticalAnchor = "top" },
    8, {191, 191, 191}
  )
end

function nodeView:nodeDrawPos(node)
  return vec2.add(self.scroll, vec2.mul(node.position, self.nodeSpacing))
end

function nodeView:nodeAt(pos)
  for _, node in pairs(self.tree.nodes) do
    if vec2.mag(vec2.sub(pos, vec2.mul(node.position, self.nodeSpacing))) <= 10 then return node end
  end
  return nil
end
























--
