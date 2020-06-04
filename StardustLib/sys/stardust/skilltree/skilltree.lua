require "/lib/stardust/itemutil.lua"
require "/lib/stardust/color.lua"

require "/sys/stardust/quickbar/conditions.lua"

skilltree = skilltree or { }

local needsRedraw = true
local skillData, itemData, saveData
local defs, nodes, connections, decorations

local scrollPos = {0, 0}
local scrollBounds = {0, 0, 0, 0}
local nodeSpacing = 16

function skilltree.init(canvas, treePath, data, saveFunc)
  saveData = saveFunc
  skillData = data or { }
  
  do -- load skill tree
    local td = root.assetJson(treePath)
    defs = root.assetJson(util.absolutePath(util.pathDirectory(treePath), td.definitions))
    
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
            grants = n.grants, skill = n.skill, target = n.target or n.to,
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
    end
    
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
  skilltree.init(canvas, treePath, itemData["stardustlib:skillData"], function(data)
    itemData["stardustlib:skillData"] = data
    saveItem(itemData)
  end)
end

function skilltree.redraw() needsRedraw = true end

function skilltree.saveChanges()
  -- TODO calculate stuffs!
  saveData(skillData)
end

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
  c:drawRect({0, 0, s[1], s[2]}, {256, 0, 0})
  
  -- connections
  local lineColors = {
    {127, 63, 63, 63},
    {127, 127, 255, 127},
    {255, 255, 255, 127},
  }
  for _, cn in pairs(connections) do
    sb.logInfo(string.format("drawing line \"%s\" between %s and %s", _, cn[1].path, cn[2].path))
    local lc = 1
    --if isNodeUnlocked(cn[1]) then lc = lc + 1 end
    --if isNodeUnlocked(cn[2]) then lc = lc + 1 end
    c:drawLine(ndp(cn[1]), ndp(cn[2]), lineColors[lc], 2)
  end
  
end

function skilltree.initUI()
  local w = skilltree.canvasWidget
  metagui.startEvent(function()
    while true do
      coroutine.yield()
      if needsRedraw then skilltree.draw() end
    end
  end)
end
