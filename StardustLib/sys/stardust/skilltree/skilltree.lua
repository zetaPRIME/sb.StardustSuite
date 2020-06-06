require "/lib/stardust/itemutil.lua"
require "/lib/stardust/color.lua"

require "/sys/stardust/quickbar/conditions.lua"

require "/sys/stardust/skilltree/tooltip.lua"
require "/sys/stardust/skilltree/calc.lua"

skilltree = skilltree or { }

local needsRedraw = true
local skillData, itemData, saveData
local defs, nodes, connections, decorations
local apToSpend = 0
local nodesToUnlock = { }

local scrollPos = {0, 0}
local scrollBounds = {0, 0, 0, 0}
local nodeSpacing = 24

local mouseOverNode

function skilltree.init(canvas, treePath, data, saveFunc)
  saveData = saveFunc
  skillData = data or { }
  skillData.unlocks = skillData.unlocks or { }
  
  do -- load skill tree
    local td = root.assetJson(treePath)
    local defsPath = util.absolutePath(util.pathDirectory(treePath), td.definitions)
    defs = root.assetJson(defsPath)
    defs.directory = util.pathDirectory(defsPath)
    skilltree.defs = defs -- provide to other modules
    
    -- make sure tables exist, set defaults
    defs.icons = defs.icons or { }
    defs.iconBasePath = defs.iconBasePath or defs.directory
    
    -- parse through nodeset
    nodes, connections = { }, { }
    local iterateTree iterateTree = function(tree, pfx, offset)
      for k, n in pairs(tree) do
        -- apply templates
        if n.template and defs.templates[n.template] then
          local _n = n
          n = { }
          for k,v in pairs(defs.templates[_n.template]) do n[k]=v end
          for k,v in pairs(_n) do n[k]=v end
        end
        
        local type = n.type or "node"
        local pos = vec2.add(n.position or {0, 0}, offset)
        local path = util.absolutePath(pfx, k)
        
        if type == "group" then
          -- group conditions; same format (and options) as quickbar ones!
          if not n.condition or condition(table.unpack(n.condition)) then --
            iterateTree(n.children or { }, path, pos)
          end
        else -- actual node
          local node = {
            path = path, type = type, default = n.default,
            position = pos, connectsTo = { },
            name = n.name, icon = n.icon, unlockedIcon = n.unlockedIcon,
            grants = n.grants or { }, skill = n.skill, target = n.target or n.to,
            fixedCost = n.fixedCost, costMult = n.costMult, itemCost = n.itemCost,
            condition = n.condition,
          }
          nodes[path] = node
          --if node.type == "socket" then jewelSockets[node] = true end
          --setNodeVisuals(node)
          if n.connectsTo then -- premake connections
            for _, cn in pairs(n.connectsTo) do
              local p1, p2 = path, util.absolutePath(pfx, cn)
              node.connectsTo[p2] = true
              if p1 > p2 then p1, p2 = p2, p1 end -- sort
              connections[string.format("%s+%s", p1, p2)] = {p1, p2}
              sb.logInfo("connection between "..p1.." and "..p2)
            end
          end
          sb.logInfo("finished node " .. node.path)
        end
        --
      end
    end
    iterateTree(td.tree, "/", {0, 0}) -- and start at root level
    
    -- post-pass now that groups are expanded
    for k, node in pairs(nodes) do
      -- calculate/expand scroll bounds
      scrollBounds[1] = math.min(scrollBounds[1], node.position[1])
      scrollBounds[3] = math.max(scrollBounds[3], node.position[1])
      scrollBounds[2] = math.min(scrollBounds[2], node.position[2])
      scrollBounds[4] = math.max(scrollBounds[4], node.position[2])
      
      -- reciprocate connections
      for p in pairs(node.connectsTo) do
        if nodes[p] then nodes[p].connectsTo[node.path] = true end
      end
      
      -- visuals
      if not node.icon then -- automatic icon assignment
        node.icon = "point" -- prefill with a "just a path" thing
        local modeHasIcon = { flat = true, increased = true, more = true }
        for _, g in pairs(node.grants) do
          if modeHasIcon[g[1]] then node.icon = g[2] break end
        end
      end
      while defs.icons[node.icon] do node.icon = defs.icons[node.icon] end -- icon defs
      node.icon = util.absolutePath(defs.iconBasePath, node.icon)
      local ext = node.icon:match('^.*%.(.-)$')
      if not ext or ext == "" then node.icon = node.icon .. ".png" end
      
      if node.type == "link" then node.fixedCost = 0 end
      skilltree.generateNodeToolTip(node) -- delegated to module so build scripts can reuse it
      if node.itemCost then -- assemble information for item requirement tooltips
        for _, d in pairs(node.itemCost) do
          d.displayName, d.rarity = itemutil.property(d, "shortdescription"), itemutil.property(d, "rarity") or "Common"
        end
      end
    end
    
    scrollBounds = rect.pad(scrollBounds, 3)
    
    -- convert connections from paths to nodes
    for p, c in pairs(connections) do
      c[1] = nodes[c[1]]
      c[2] = nodes[c[2]]
    end
    
  end
  
  skilltree.canvasWidget = canvas
  skilltree.canvas = widget.bindCanvas(canvas.backingWidget)
  skilltree.initUI()
end

function skilltree.initFromItem(canvas, loadItem, saveItem)
  itemData = ((type(loadItem) == "table") and loadItem) or loadItem()
  local treePath = itemutil.relativePath(itemData, itemutil.property(itemData, "stardustlib:skillTree"))
  
  --itemData["stardustlib:skillData"] = itemData["stardustlib:skillData"] or { }
  skilltree.init(canvas, treePath, itemData.parameters["stardustlib:skillData"], function(data)
    itemData.parameters["stardustlib:skillData"] = data
    saveItem(itemData)
  end)
end

function skilltree.redraw() needsRedraw = true end

function skilltree.recalculateStats()
  
end

function skilltree.resetChanges()
  apToSpend = 0
  nodesToUnlock = { }
  skilltree.redraw()
end
function skilltree.applyChanges()
  -- commit nodes
  for k,v in pairs(nodesToUnlock) do skillData.unlocks[k] = v end
  -- TODO actually implement AP
  skilltree.resetChanges()
  skilltree.saveChanges()
  skilltree.redraw()
end
function skilltree.saveChanges()
  -- TODO figure out separate calc and display, since we need to save any time a module is changed
  skilltree.recalculateStats()
  saveData(skillData)
end

function skilltree.nodeUnlockLevel(n)
  n = type(n) == "table" and n or nodes[n]
  if not n then return 0 end
  if n.default or skillData.unlocks[n.path] then return 1 end
  if nodesToUnlock[n.path] then return 0.5 end
  return 0
end

function skilltree.currentAP()
  return 1
end
function skilltree.nodeCost(n)
  return 1 -- TEMP, TODO
end

function skilltree.canAffordNode(n)
  return true -- TODO actually implement AP
end

function skilltree.tryUnlockNode(n)
  n = type(n) == "table" and n or nodes[n]
  if not n or not skilltree.canAffordNode(n) then return false end
  nodesToUnlock[n.path] = { skilltree.nodeCost(n), n.itemCost }
  skilltree.recalculateStats()
  skilltree.redraw()
end

local border = {
  {-1, 0},
  {1, 0},
  {0, -1},
  {0, 1},
}
local lineColors = {
  {127, 63, 63, 63},
  {127, 127, 255, 127},
  {255, 255, 255, 127},
}
local rarityColors = {
  common = "",
  uncommon = "^#42c53e;",
  rare = "^#3ea8c5;",
  legendary = "^#893ec5;",
  essential = "^#c3c53e;"
}
local nodeDirectives = {
  [0] = "?multiply=7f7f7f",
  h = "?border=1=ffffff5f",
  [0.5] = "?border=1=ffac61bf",
  [1] = "",
}
function skilltree.draw()
  needsRedraw = false
  local c = skilltree.canvas
  local s = c:size()
  local cp = vec2.mul(s, 0.5)
  
  local function apos(p)
    return vec2.add(cp, vec2.mul(p, {1, -1}))
  end
  local function spos(p) return apos(vec2.sub(p, scrollPos)) end
  local function ndp(n)
    --n = type(n) == "table" and n or nodes[n]
    return spos(vec2.mul(n.position, nodeSpacing))
  end
  
  -- bg
  c:clear()
  c:drawRect({0, 0, s[1], s[2]}, {15, 0, 23})
  
  -- connections
  for _, cn in pairs(connections) do
    --sb.logInfo(string.format("drawing line \"%s\" between %s and %s", _, cn[1].path, cn[2].path))
    local lc = 1
    if skilltree.nodeUnlockLevel(cn[1]) > 0 then lc = lc + 1 end
    if skilltree.nodeUnlockLevel(cn[2]) > 0 then lc = lc + 1 end
    c:drawLine(ndp(cn[1]), ndp(cn[2]), lineColors[lc], 2)
  end
  
  -- nodes
  for _, node in pairs(nodes) do
    local pos = ndp(node)
    local dm = nodeDirectives[skilltree.nodeUnlockLevel(node)]
    if mouseOverNode == node then dm = dm .. nodeDirectives["h"] end
    c:drawImage(node.icon .. dm, pos, 1, {255, 255, 255}, true)
    if node.contentsIcon then
      c:drawImage(node.contentsIcon, pos, 1, {255, 255, 255}, true)
    end
  end
  
  -- tooltip
  if mouseOverNode then
    local ttPos = vec2.add(ndp(mouseOverNode), {12, 4})
    local tt = mouseOverNode.toolTip
    if skilltree.nodeUnlockLevel(mouseOverNode) == 0 then
      if mouseOverNode.itemCost then
        local ctt = { }
        local hasAll = true
        for _, d in pairs(mouseOverNode.itemCost) do
          local has = player.hasCountOfItem(d, true) >= d.count
          hasAll = has and hasAll
          table.insert(ctt, string.format("- %s%d ^reset;%s%s^reset;\n", has and "^white;" or "^red;", d.count, has and rarityColors[d.rarity:lower()] or "^red;", d.displayName))
        end
        table.insert(ctt, 1, string.format("%sMaterial cost^reset;:\n", hasAll and "" or "^red;"))
        tt = tt .. table.concat(ctt)
      end
      local cost, fixed = skilltree.nodeCost(mouseOverNode)
      if cost > 0 then -- only display nonzero costs
        tt = string.format("%s%s: %s%d ^violet;AP^reset;\n", tt, fixed and "Fixed cost" or "Cost", skilltree.currentAP() >= cost and "^white;" or "^red;", cost)
      end
    end
    local btt = tt:gsub("(%b^;)", "") -- strip codes for border
    for _, off in pairs(border) do
      c:drawText(btt, { position = vec2.add(ttPos, off), horizontalAnchor = "left", verticalAnchor = "top", wrapWidth = toolTipWidth }, 8, {0, 0, 0, 200})
    end
    c:drawText(tt, { position = ttPos, horizontalAnchor = "left", verticalAnchor = "top", wrapWidth = toolTipWidth }, 8, {191, 191, 191})
    
  end

  --[[c:drawText(
  string.format("^shadow;^white;%d ^violet;AP^reset;", math.floor(currentAP())),
  { position = {480.0, 508.0}, horizontalAnchor = "mid", verticalAnchor = "top" },
  8, {191, 191, 191}
)]]
  
end

function skilltree.scroll(d)
  scrollPos = {
    util.clamp(scrollPos[1] + d[1], scrollBounds[1] * nodeSpacing, scrollBounds[3] * nodeSpacing),
    util.clamp(scrollPos[2] + d[2], scrollBounds[2] * nodeSpacing, scrollBounds[4] * nodeSpacing),
  }
  skilltree.redraw()
end

function findMouseOver(mp)
  local old = mouseOverNode
  mouseOverNode = nil
  local buf = 0.4
  local mtp = vec2.div(vec2.add(vec2.sub(mp, vec2.mul(skilltree.canvasWidget.size, 0.5)), scrollPos), nodeSpacing)
  if old and vec2.mag(vec2.sub(mtp, old.position)) <= buf then
    mouseOverNode = old
    return nil -- still on previous node, no change
  end
  for _, n in pairs(nodes) do
    if vec2.mag(vec2.sub(mtp, n.position)) <= buf then
      mouseOverNode = n
      break
    end
  end
  if mouseOverNode ~= old then skilltree.redraw() end
end
function clearMouseOver()
  if mouseOverNode then skilltree.redraw() end
  mouseOverNode = nil
end

function skilltree.clickNode(n)
  n = type(n) == "table" and n or nodes[n]
  -- TODO
  local lv = skilltree.nodeUnlockLevel(n)
  if lv == 0 then
    local s = skilltree.tryUnlockNode(n)
  end
end

function skilltree.initUI()
  local w = skilltree.canvasWidget
  metagui.startEvent(function()
    local omp = {0, 0} -- old mouse pos
    while true do
      coroutine.yield()
      
      -- handle mouse movement
      local mp = w:relativeMousePosition()
      if not vec2.eq(mp, omp) then
        if not rect.contains(rect.withSize({0, 0}, w.size), mp) then
          clearMouseOver()
        else
          findMouseOver(mp)
        end
      end omp = mp
      
      -- and redrawing
      if needsRedraw then skilltree.draw() end
    end
  end)
  
  function w:onMouseButtonEvent(btn, down)
    if down then
      if btn == 0 then
        if mouseOverNode then
          skilltree.clickNode(mouseOverNode)
          return nil
        end
      end
      self:captureMouse(btn)
    elseif btn == self:mouseCaptureButton() then
      self:releaseMouse()
    end
  end
  
  function w:onCaptureMouseMove(d)
    if d[1] ~= 0 or d[2] ~= 0 then
      skilltree.scroll(vec2.mul(d, {-1, 1}))
    end
  end
end
