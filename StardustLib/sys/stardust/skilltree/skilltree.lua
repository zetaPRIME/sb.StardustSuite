require "/lib/stardust/itemutil.lua"
require "/lib/stardust/color.lua"

require "/sys/quickbar/conditions.lua"

require "/sys/stardust/skilltree/tooltip.lua"
require "/sys/stardust/skilltree/calc.lua"

skilltree = skilltree or { }
skilltree.modifyStatDisplay = { }

skilltree.zoom = 1

local needsRedraw = true
local mouseRefresh
local skillData, itemData, saveData
local defs, nodes, connections, decorations, defaultUnlocks
local apToSpend = 0
local fixedCosts = 0
local nodesToUnlock = { }

local scrollPos = {0, 0}
local scrollBounds = {0, 0, 0, 0}
local nodeSpacing = 24

local mouseOverNode

local soundEffects = {
  unlock = "/sfx/objects/ancientenergy_chord.ogg",
  error = "/sfx/interface/clickon_error.ogg",
  apply = "/sfx/objects/essencechest_open3.ogg",
  reset = "/sfx/interface/nav_insufficient_fuel.ogg",
  
  socketPlace = { "/sfx/melee/sword_parry.ogg", "/sfx/objects/essencechest_open2.ogg" },
  socketRemove = { },--"/sfx/objects/ancientenergy_pickup1.ogg",
  
  selector = { "/sfx/objects/outpostbutton.ogg", "/sfx/objects/ancientenergy_pickup1.ogg" },
  deselect = { "/sfx/objects/outpostbutton.ogg", "/sfx/interface/nav_insufficient_fuel.ogg" },
  
  link = { "/sfx/interface/stationtransponder_stationpulse.ogg", "/sfx/tech/tech_dash.ogg" },
  zoom = "/sfx/interface/stationtransponder_stationpulse.ogg",
}

local rarityColors = {
  common = "",
  uncommon = "^#42c53e;",
  rare = "^#3ea8c5;",
  legendary = "^#893ec5;",
  essential = "^#c3c53e;"
}

local layoutFunc = { }
function layoutFunc.radial(pos, div, offset, taper)
  div = div or 1
  offset = offset or 0
  taper = taper or 0
  local r = (pos[1]/div + offset) * math.pi*2
  local e = pos[2]+(taper*pos[1])
  return {math.sin(r) * math.abs(e), math.cos(r) * -e}
end

function skilltree.playSound(sfx)
  local s = soundEffects[sfx]
  if type(s) == "string" then s = {s} end
  for _, s in pairs(s) do pane.playSound(s) end
end
local sfx = skilltree.playSound -- alias

function skilltree.init(canvas, treePath, data, saveFunc)
  saveData = saveFunc
  skillData = data or { }
  skillData.unlocks = skillData.unlocks or { }
  skillData.modules = skillData.modules or { }
  skillData.selectors = skillData.selectors or { }
  
  do -- load skill tree
    local td = root.assetJson(treePath)
    local defsPath = util.absolutePath(util.pathDirectory(treePath), td.definitions)
    defs = root.assetJson(defsPath)
    defs.directory = util.pathDirectory(defsPath)
    skilltree.defs = defs -- provide to other modules
    
    -- make sure tables exist, set defaults
    defs.icons = defs.icons or { }
    defs.iconBasePath = defs.iconBasePath or defs.directory
    defs.baseStats = defs.baseStats or { }
    defs.baseNodeCost = defs.baseNodeCost or 1000
    defs.costExponent = defs.costExponent or 1.1
    
    -- merge in overrides from tree
    util.mergeTable(defs.baseStats, td.baseStats or { })
    util.mergeTable(defs.statNames, td.statNames or { })
    defs.statsDisplay = td.statsDisplay or defs.statsDisplay or { }
    for k,v in pairs(td.templates or { }) do defs.templates[k] = v end -- template overrides
    
    -- parse through nodeset
    nodes, connections, defaultUnlocks = { }, { }, { }
    local iterateTree iterateTree = function(tree, pfx, offset, lf)
      if lf then
        if type(lf) == "string" then lf = {lf} end
        lf[1] = layoutFunc[lf[1]]
        if not lf[1] then lf = nil end
      end
      if pfx:sub(-1) ~= "/" then pfx = pfx .. "/" end -- directorize path
      for k, n in pairs(tree) do
        -- apply templates
        while n.template and defs.templates[n.template] do
          local _n = n
          n = { }
          for k,v in pairs(defs.templates[_n.template]) do n[k]=v end
          _n.template = nil -- don't reapply the same template over and over
          for k,v in pairs(_n) do n[k]=v end
        end
        
        local type = n.type or "node"
        local pos = n.position or {0, 0}
        if lf then pos = lf[1](pos, table.unpack(lf, 2)) end
        pos = vec2.add(pos, offset)
        local path = util.absolutePath(pfx, k)
        
        if type == "group" then
          -- group conditions; same format (and options) as quickbar ones!
          if not n.condition or condition(table.unpack(n.condition)) then --
            iterateTree(n.children or { }, path, pos, n.layoutFunction or n.layoutFunc or n.layout)
          end
        else -- actual node
          local node = {
            path = path, type = type, default = n.default,
            position = pos, connectsTo = { },
            name = n.name, icon = n.icon, unlockedIcon = n.unlockedIcon,
            grants = n.grants or { }, skill = n.skill, target = n.target or n.to,
            fixedCost = n.fixedCost, costMult = n.costMult, itemCost = n.itemCost,
            condition = n.condition, moduleTypes = n.moduleTypes, disableGrants = n.disableGrants,
            canDeselect = n.canDeselect,
          }
          nodes[path] = node
          if node.type == "link" then
            node.default = true -- no reason for one of these to be locked
            node.target = util.absolutePath(pfx, node.target or "")
          end
          if node.default then defaultUnlocks[node.path] = true end
          if n.connectsTo then -- premake connections
            for _, cn in pairs(n.connectsTo) do
              local p1, p2 = path, util.absolutePath(pfx, cn)
              node.connectsTo[p2] = true
              if p1 > p2 then p1, p2 = p2, p1 end -- sort
              connections[string.format("%s+%s", p1, p2)] = {p1, p2}
            end
          end
        end
        --
      end
    end
    iterateTree(td.tree, "/", td.rootPosition or {0, 0}) -- and start at root level
    
    -- post-pass now that groups are expanded
    for k, node in pairs(nodes) do
      -- reciprocate connections
      for p in pairs(node.connectsTo) do
        if nodes[p] then
          nodes[p].connectsTo[node.path] = true
        else node.connectsTo[p] = nil end -- delete invalid
      end
    end for k, node in pairs(nodes) do -- another one since some of this needs connections statted out
      -- calculate/expand scroll bounds
      scrollBounds[1] = math.min(scrollBounds[1], node.position[1])
      scrollBounds[3] = math.max(scrollBounds[3], node.position[1])
      scrollBounds[2] = math.min(scrollBounds[2], node.position[2])
      scrollBounds[4] = math.max(scrollBounds[4], node.position[2])
      
      -- visuals
      if not node.icon then -- automatic icon assignment
        node.icon = node.type -- prefill with a "just a path" thing
        local modeHasIcon = { flat = true, increased = true, more = true }
        for _, g in pairs(node.grants) do
          if modeHasIcon[g[1]] then node.icon = g[2] break end
        end
      end
      while defs.icons[node.icon] do node.icon = defs.icons[node.icon] end -- icon defs
      node.icon = util.absolutePath(defs.iconBasePath, node.icon)
      local ext = node.icon:match('^.*%.(.-)$')
      if not ext or ext == "" then node.icon = node.icon .. ".png" end
      
      if node.type == "link" or node.type == "selection" then node.fixedCost = 0 end
      if node.type == "selection" then -- find master
        for p in pairs(node.connectsTo) do
          local n = nodes[p]
          if n and n.type == "selector" then node.selector = p break end
        end
      end
      skilltree.refreshNodeProperties(node)
      if node.itemCost then -- assemble information for item requirement tooltips
        for _, d in pairs(node.itemCost) do
          d.displayName, d.rarity = itemutil.property(d, "shortdescription"), itemutil.property(d, "rarity") or "Common"
        end
      end
    end
    
    scrollBounds = rect.pad(scrollBounds, 3)
    
    -- convert connections from paths to nodes
    for p, c in pairs(connections) do
      c[1], c[2] = nodes[c[1]], nodes[c[2]]
      -- delete invalid connections
      if not c[1] or not c[2] then connections[p] = nil end 
    end
    
    local refundAll = (skillData.compatId ~= td.compatId)
    
    -- refund nonexistent nodes, or all if breaking changes have occurred
    for p in pairs(skillData.unlocks) do
      if refundAll or not nodes[p] then skilltree.refundNode(p, true) end
    end
    for p in pairs(skillData.modules) do -- take care of formerly default-unlocked sockets too
      if not nodes[p] or skilltree.nodeUnlockLevel(p) < 1 then skilltree.refundNode(p, true) end
    end
    
    if type(defs.scripts) == "table" then
      for _, p in pairs(defs.scripts) do require(util.absolutePath(util.pathDirectory(treePath), p)) end
    end
    
    if type(td.scripts) == "table" then
      for _, p in pairs(td.scripts) do require(util.absolutePath(util.pathDirectory(defsPath), p)) end
    end
    
    skillData.compatId = td.compatId
    skilltree.recalculateStats() -- update all the things
  end
  
  skilltree.canvasWidget = canvas
  skilltree.canvas = widget.bindCanvas(canvas.backingWidget)
  if not skillData.uuid then
    skillData.uuid = sb.makeUuid()
  end
  skilltree.uuid = skillData.uuid
  skilltree.saveChanges()
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

function skilltree.refreshNodeProperties(node)
  node = type(node) == "table" and node or nodes[node]
  if not node then return nil end
  if node.type == "socket" then
    local m = skillData.modules[node.path]
    if m then -- 
      node.moduleName = string.format("^lightgray;%s%s^reset;", rarityColors[string.lower(itemutil.property(m, "rarity") or "common")], itemutil.property(m, "shortdescription"))
      node.contentsIcon = itemutil.relativePath(m, itemutil.property(m, "inventoryIcon"))
      node.moduleGrants = nil
      if node.disableGrants then
        node.moduleGrants = { {"description", "^gray;(No stats granted)^reset;"} }
      else
        local ms = itemutil.property(m, "stardustlib:moduleStats") or { }
        for _, t in pairs(node.moduleTypes or { }) do
          if ms[t] then node.moduleGrants = ms[t] break end
        end
      end
    else -- socket empty
      node.moduleName, node.moduleGrants, node.contentsIcon = nil
    end
  elseif node.type == "selector" then
    local s = nodes[skillData.selectors[node.path] or false]
    node.effGrants = s and s.grants
  end
  skilltree.generateNodeToolTip(node) -- delegated to module so build scripts can reuse it
end

skilltree.statModifiers = { }
function skilltree.recalculateStats(saveBeforeDisplay)
  skillData.spentAP = 0
  skillData.stats, skillData.flags, skillData.effects = { }, { }, { }
  for stat, v in pairs(defs.baseStats) do
    if type(v) == "number" then v = {v} end
    skillData.stats[stat] = { v[1] or 0, v[2] or 1, v[3] or 1 }
  end
  
  local isStatMod = { flat = true, increased = true, more = true }
  local function doGrants(node, stats)
    local doFlags = stats == nil
    stats = stats or skillData.stats
    for _, g in pairs(node.effGrants or node.moduleGrants or node.grants or { }) do
      local mode, stat, amt = table.unpack(g)
      if isStatMod[mode] and stat then
        if not stats[stat] then stats[stat] = {0, 1, 1} end
        if mode == "flat" then stats[stat][1] = stats[stat][1] + amt
        elseif mode == "increased" then stats[stat][2] = stats[stat][2] + amt
        elseif mode == "more" then stats[stat][3] = stats[stat][3] * (1.0 + amt)
        end
      elseif not doFlags then
      elseif mode == "flag" and stat then skillData.flags[stat] = amt == nil or amt
      elseif mode == "effect" and stat then table.insert(skillData.effects, stat)
      end --
    end
  end
  for path in pairs(defaultUnlocks) do
    local node = nodes[path]
    if node then doGrants(node) end
  end
  for path, unlock in pairs(skillData.unlocks) do
    local node = nodes[path]
    if node then -- TODO: sockets
      -- keep track of total AP spent on non-fixed-cost nodes
      if not unlock[2] then skillData.spentAP = skillData.spentAP + unlock[1] end
      doGrants(node)
    end
  end
  
  -- allow individual things to modify calculated stats
  for _, m in pairs(skilltree.statModifiers) do m(skillData.stats, skillData.flags) end
  
  if saveBeforeDisplay then skilltree.saveChanges(true) end
  
  -- update display
  if statsDisplay then
    -- calculate display stat values
    local displayStats = util.mergeTable({ }, skillData.stats)
    for path in pairs(nodesToUnlock) do doGrants(nodes[path], displayStats) end
    
    local statNames = (skilltree.defs or { }).statNames or { }
    local statPercent = (skilltree.defs or { }).statPercent or { }
    local tt = { }
    local lastBlank = false
    for _, stat in pairs(defs.statsDisplay) do
      if stat ~= "" then
        local calc = skilltree.calculateFinalStat(displayStats[stat] or {0, 0, 0})
        local txt = string.format("^white;%s ^cyan;%s^reset;", skilltree.displayNumber(calc, statPercent[stat]), statNames[stat] or stat)
        local f = skilltree.modifyStatDisplay[stat]
        txt = f and f(txt, calc) or txt
        if txt ~= "" then
          table.insert(tt, txt)
          table.insert(tt, "\n")
          lastBlank = false
        end
      else
        if not lastBlank then table.insert(tt, "\n") end
        lastBlank = true
      end
    end
    statsDisplay:setText(table.concat(tt))
  end
end

function skilltree.resetChanges(silent)
  local found
  for _, c in pairs(nodesToUnlock) do
    found = true
    if c[3] then
      for _, itm in pairs(c[3]) do player.giveItem(itm) end
    end
  end
  if not found then return nil end
  apToSpend = 0
  fixedCosts = 0
  nodesToUnlock = { }
  if not silent then sfx "reset" end
  skilltree.recalculateStats()
  skilltree.redraw()
end
function skilltree.applyChanges(silent)
  local found
  for _ in pairs(nodesToUnlock) do found = true break end
  if not found then return nil end
  if skilltree.currentAP() < 0 then -- no trying to game the system :|
    if not silent then sfx "error" end
    return nil
  end
  -- commit nodes
  for k,v in pairs(nodesToUnlock) do skillData.unlocks[k] = v end
  player.setProperty("stardustlib:ap", (player.getProperty("stardustlib:ap") or 0) - apToSpend)
  apToSpend = 0
  fixedCosts = 0
  nodesToUnlock = { }
  if not silent then sfx "apply" end
  skilltree.saveChanges()
  skilltree.redraw()
end
function skilltree.saveChanges(fromRecalc)
  if not fromRecalc then skilltree.recalculateStats() end
  skillData.syncId = sb.makeUuid()
  saveData(skillData)
end

function skilltree.nodeUnlockLevel(n, visual)
  n = type(n) == "table" and n or nodes[n]
  if not n then return 0 end
  if n.type == "selection" then
    if skilltree.nodeUnlockLevel(n.selector) < 1 then return 0 end
    if skillData.selectors[n.selector] == n.path then
      return 1
    else
      return 0.9
    end
  end
  if n.default or skillData.unlocks[n.path] then return 1 end
  if nodesToUnlock[n.path] then return 0.5 end
  if visual then for c in pairs(n.connectsTo) do
    if skilltree.nodeUnlockLevel(c) >= 0.5 then return -0.1 end
  end end
  return 0
end

function skilltree.currentAP()
  return (player.getProperty("stardustlib:ap") or 0) - apToSpend
end
function skilltree.nodeCost(n)
  if n.fixedCost then return n.fixedCost, true end
  local spent = skillData.spentAP + apToSpend - fixedCosts
  local bcost = defs.baseNodeCost
  local ncost = bcost * (n.costMult or 1)
  
  return ncost * (1.0 + (spent/bcost) * (defs.costExponent-1))
  --return math.floor(defs.baseNodeCost * (n.costMult or 1) * defs.costExponent ^ (spent / defs.baseNodeCost)) -- TEMP, TODO
end

function skilltree.canAffordNode(n)
  if skilltree.nodeCost(n) > skilltree.currentAP() then return false end
  if n.itemCost then for _, d in pairs(n.itemCost) do
    local cur = itemutil.property(d, "currency")
    if cur then
      if player.currency(cur) < d.count then return false end
    elseif player.hasCountOfItem(d, true) < d.count then return false end
  end end
  return true
end

function skilltree.tryUnlockNode(n)
  n = type(n) == "table" and n or nodes[n]
  if not n or not skilltree.canAffordNode(n) then sfx "error" return false end
  local pass for cn in pairs(n.connectsTo) do
    if skilltree.nodeUnlockLevel(cn) > 0 then pass = true break end
  end
  if not pass then sfx "error" return false end
  local cost = skilltree.nodeCost(n)
  apToSpend = apToSpend + cost
  if n.fixedCost then fixedCosts = fixedCosts + cost end
  local u = { cost, not not n.fixedCost, n.itemCost }
  if not u[3] and not u[2] then -- truncate
    u[2] = nil u[3] = nil
  end
  nodesToUnlock[n.path] = u
  if n.itemCost then -- actually take material costs now
    for _, d in pairs(n.itemCost) do 
      local cur = itemutil.property(d, "currency")
      if cur then player.consumeCurrency(cur, d.count)
      else player.consumeItem(d, false, true) end
    end
  end
  sfx "unlock"
  skilltree.recalculateStats()
  skilltree.redraw()
  return true
end

function skilltree.refundAll()
  for p in pairs(skillData.unlocks) do skilltree.refundNode(p, true) end
  skilltree.saveChanges()
  skilltree.redraw()
end
function skilltree.refundNode(path, batch)
  path = type(path) == "table" and path.path or path -- we need specifically the path for this
  local c = skillData.unlocks[path] or {0}
  if c[1] ~= 0 then player.setProperty("stardustlib:ap", player.getProperty("stardustlib:ap", 0) + c[1]) end
  for k, i in pairs(c[3] or { }) do player.giveItem(i) end
  skillData.unlocks[path] = nil
  local m = skillData.modules[path]
  if m then player.giveItem(m) end
  skillData.modules[path] = nil
  skillData.selectors[path] = nil -- clear this too to prevent accretion
  skilltree.refreshNodeProperties(path) -- clear out socket details
  if not batch then
    skilltree.recalculateStats()
    skilltree.saveChanges()
    skilltree.redraw()
  end
end

function skilltree.trySocketNode(node, itm)
  if node.type ~= "socket" then return itm end -- nope
  local cur = skillData.modules[node.path]
  local count = 0
  if itm then count = itm.count end
  if count > 1 and cur and cur.count >= 1 then -- reject, no multifill
    sfx "error"
    return itm
  end
  if count == 0 then -- just pull out what's in there
    if not cur then return nil end -- nothing to remove
    sfx "socketRemove"
    skillData.modules[node.path] = nil
    skilltree.refreshNodeProperties(node)
    skilltree.recalculateStats(true) -- save changes before adding uncommitted nodes for display
    skilltree.redraw()
    return cur
  else -- swap
    -- check if it's a valid module for the socket
    local fits = false
    local ms = itemutil.property(itm, "stardustlib:moduleStats") or { }
    for _, t in pairs(node.moduleTypes or { }) do
      if ms[t] then fits = true break end
    end
    if not fits then
      sfx "error"
      return itm
    end
    sfx "socketPlace"
    skillData.modules[node.path] = { name = itm.name, count = 1, parameters = itm.parameters }
    skilltree.refreshNodeProperties(node)
    skilltree.recalculateStats(true) -- save changes before adding uncommitted nodes for display
    skilltree.redraw()
    -- can only get here with a count >1 if there's nothing in there already
    if count > 1 then return { name = itm.name, count = itm.count - 1, parameters = itm.parameters } end
    return cur
  end
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
  
  selector = {127, 191, 255, 127},
}
local nodeDirectives = {
  [-0.1] = "?multiply=bfbfbf?border=1=ffffff1f", -- unlock path available
  [0] = "?multiply=7f7f7f",
  h = "?border=1=ffffff5f",
  [0.5] = "?border=1=ffac61bf",
  [0.9] = "?multiply=7f7f7f?border=1=bfdfff3f", -- inactive selections
  [1] = "",
}
local toolTipBG = metagui.theme.assets.panel--metagui.ninePatch("/metagui/themes/fallbackAssets/panel")
function skilltree.draw()
  local nodeSpacing = nodeSpacing * skilltree.zoom
  
  needsRedraw = false
  local c = skilltree.canvas
  local s = c:size()
  local cp = vec2.mul(s, 0.5)
  
  local visRect = rect.withCenter(vec2.div(scrollPos, nodeSpacing), vec2.add(vec2.div(s, nodeSpacing), 1))
  
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
  skilltree.drawBackground(scrollPos)
  
  -- connections
  for _, cn in pairs(connections) do
    if rect.contains(visRect, cn[1].position) or rect.contains(visRect, cn[2].position) then
      local lc, lw = 1, 2
      if skilltree.nodeUnlockLevel(cn[1]) > 0 then lc = lc + 1 end
      if skilltree.nodeUnlockLevel(cn[2]) > 0 then lc = lc + 1 end
      if (cn[1].type == "selection" and cn[2].type == "selector") or (cn[1].type == "selector" and cn[2].type == "selection") then
        lc, lw = "selector", 4
      end
      c:drawLine(ndp(cn[1]), ndp(cn[2]), lineColors[lc], math.max(1, lw * skilltree.zoom))
    end
  end
  
  -- nodes
  for _, node in pairs(nodes) do
    if rect.contains(visRect, node.position) then
      local pos = ndp(node)
      local ul = skilltree.nodeUnlockLevel(node, true)
      local dm = nodeDirectives[ul]
      if mouseOverNode == node then dm = dm .. nodeDirectives["h"] end
      local icon = node.icon
      if icon:sub(-1) == ":" then icon = icon .. (ul <= 0 and "locked" or ul <= 0.5 and "pending" or "unlocked") end
      c:drawImage(icon .. dm, pos, skilltree.zoom, {255, 255, 255}, true)
      if node.contentsIcon then
        c:drawImage(node.contentsIcon, pos, skilltree.zoom, {255, 255, 255}, true)
      end
    end
  end
  
  -- tooltip
  if mouseOverNode and (skilltree.canvasWidget:mouseCaptureButton() or -1) < 1 then
    local ttPos = vec2.add(ndp(mouseOverNode), {14, 4})
    --local toolTipWidth = s[1] - ttPos[1]
    local toolTipWidth = s[1]/2 - 24
    toolTipWidth = util.clamp(s[1] - ttPos[1] - 1, toolTipWidth*0.6, toolTipWidth) -- autoscale down, to a reasonable point
    local tt = mouseOverNode.toolTip
    if player.isAdmin() then tt = string.format("^darkgray;%s^reset;\n%s", mouseOverNode.path, tt) end
    if skilltree.nodeUnlockLevel(mouseOverNode, true) < 0 then
      if mouseOverNode.itemCost then
        local ctt = { }
        local hasAll = true
        for _, d in pairs(mouseOverNode.itemCost) do
          local has
          local cur = itemutil.property(d, "currency")
          if cur then has = player.currency(cur) >= d.count
          else has = player.hasCountOfItem(d, true) >= d.count end
          hasAll = has and hasAll
          table.insert(ctt, string.format("- %s%d ^reset;%s%s^reset;\n", has and "^white;" or "^red;", d.count, has and rarityColors[d.rarity:lower()] or "^red;", d.displayName))
        end
        table.insert(ctt, 1, string.format("%sMaterial cost^reset;:\n", hasAll and "" or "^red;"))
        tt = tt .. table.concat(ctt)
      end
      local cost, fixed = skilltree.nodeCost(mouseOverNode)
      if cost > 0 then -- only display nonzero costs
        tt = string.format("%s%s: %s%s ^violet;AP^reset;\n", tt, fixed and "Fixed cost" or "Cost", skilltree.currentAP() >= cost and "^white;" or "^red;", tonumber(math.floor(cost)))
      end
    elseif mouseOverNode.type == "selector" and mouseOverNode.canDeselect then
      if skilltree.nodeUnlockLevel(mouseOverNode) == 1 and skillData.selectors[mouseOverNode.path] then
        tt = string.format("%s^gray;%s^reset;\n", tt, "(click to deselect)")
      end
    elseif mouseOverNode.type == "selection" then
      local sel = skillData.selectors[mouseOverNode.selector] == mouseOverNode.path
      tt = string.format("%s^gray;%s^reset;\n", tt, sel and "(selected option)" or "(click to select this option)")
    end
    --[[] ]local btt = tt:gsub("(%b^;)", "") -- strip codes for border
    for _, off in pairs(border) do
      c:drawText(btt, { position = vec2.add(ttPos, off), horizontalAnchor = "left", verticalAnchor = "top", wrapWidth = toolTipWidth }, 8, {0, 0, 0, 200})
    end--]]
    local ttSize = metagui.measureString(tt, toolTipWidth)
    if vec2.mag(ttSize) > 2 then -- only display if there's actual text
      local ttc = vec2.add(ttPos, vec2.mul(ttSize, {0.5, -0.5}))
      local ttr = rect.withCenter(ttc, vec2.add(ttSize, 2*3))
      toolTipBG:drawToCanvas(c, "concave", ttr)
    end
    
    c:drawText(tt, { position = ttPos, horizontalAnchor = "left", verticalAnchor = "top", wrapWidth = toolTipWidth }, 8, {191, 191, 191})
    
  end

  --[[c:drawText(
  string.format("^shadow;^white;%d ^violet;AP^reset;", math.floor(currentAP())),
  { position = {480.0, 508.0}, horizontalAnchor = "mid", verticalAnchor = "top" },
  8, {191, 191, 191}
)]]
end

function skilltree.drawBackground() end -- stub

function skilltree.scrollPosition() return scrollPos end
function skilltree.scroll(d)
  local nodeSpacing = nodeSpacing * skilltree.zoom
  scrollPos = {
    util.clamp(scrollPos[1] + d[1], scrollBounds[1] * nodeSpacing, scrollBounds[3] * nodeSpacing),
    util.clamp(scrollPos[2] + d[2], scrollBounds[2] * nodeSpacing, scrollBounds[4] * nodeSpacing),
  }
  skilltree.redraw()
end
function skilltree.scrollTo(d)
  local nodeSpacing = nodeSpacing * skilltree.zoom
  scrollPos = {
    util.clamp(d[1], scrollBounds[1] * nodeSpacing, scrollBounds[3] * nodeSpacing),
    util.clamp(d[2], scrollBounds[2] * nodeSpacing, scrollBounds[4] * nodeSpacing),
  }
  skilltree.redraw()
end
function skilltree.setZoom(z)
  local p = z / skilltree.zoom
  skilltree.zoom = z
  mouseRefresh = true
  skilltree.scrollTo {scrollPos[1] * p, scrollPos[2] * p}
end

function findMouseOver(mp)
  local nodeSpacing = nodeSpacing * skilltree.zoom
  
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
  if n.type == "link" then
    if nodes[n.target] then
      sfx "link"
      metagui.startEvent(function()
        local f = 10 -- frames for jump
        local op = scrollPos
        local tp = vec2.mul(nodes[n.target].position, nodeSpacing)
        local diff = vec2.sub(tp, op)
        for i=1,f do
          skilltree.scrollTo(vec2.add(op, vec2.mul(diff, i/f)))
          mouseRefresh = true
          coroutine.yield()
        end
      end)
    end
  elseif n.type == "selection" then
    if skilltree.nodeUnlockLevel(n.selector) < 1 then
      sfx "error"
    elseif skillData.selectors[n.selector] ~= n.path then
      sfx "selector"
      skillData.selectors[n.selector] = n.path
      skilltree.refreshNodeProperties(n.selector)
      skilltree.recalculateStats(true)
      skilltree.redraw()
    end
  elseif n.type == "selector" and skilltree.nodeUnlockLevel(n) == 1 then
    if n.canDeselect and skillData.selectors[n.path] then
      sfx "deselect"
      skillData.selectors[n.path] = nil
      skilltree.refreshNodeProperties(n)
      skilltree.recalculateStats(true)
      skilltree.redraw()
    end
  elseif n.type == "socket" and skilltree.nodeUnlockLevel(n) == 1 then
    local itm = player.swapSlotItem()
    local cur = skilltree.trySocketNode(n, itm)
    -- allow shift+click if cursor empty
    if cur and not itm and metagui.checkShift() then
      player.setSwapSlotItem(nil)
      player.giveItem(cur)
    else player.setSwapSlotItem(cur) end
  else -- plain node
    local lv = skilltree.nodeUnlockLevel(n)
    if lv <= 0 then
      local s = skilltree.tryUnlockNode(n)
    end
  end
end

function skilltree.initUI()
  local w = skilltree.canvasWidget
  metagui.startEvent(function()
    local omp = {0, 0} -- old mouse pos
    while true do
      if apDisplay then -- handle AP label
        local txt = string.format("^white;%d ^violet;AP^reset;", math.floor(skilltree.currentAP()))
        if apToSpend > 0 then txt = string.format("%s ^lightgray;(^white;%d^lightgray; spent)", txt, math.floor(apToSpend)) end
        apDisplay:setText(txt)
      end
      
      coroutine.yield()
      
      -- handle mouse movement
      local mp = w:relativeMousePosition()
      if mouseRefresh or not vec2.eq(mp, omp) then
        mouseRefresh = false
        if not w:isMouseOver() then
          clearMouseOver()
        else
          findMouseOver(mp)
        end
      end omp = mp
      
      -- and redrawing
      if needsRedraw then skilltree.draw() end
    end
  end)
  metagui.registerUninit(function()
    -- refund any item costs incurred but not committed
    skilltree.resetChanges()
  end)
  
  local zooming = false
  function w:onMouseButtonEvent(btn, down)
    if down then
      if btn == 0 then
        if mouseOverNode then
          metagui.startEvent(skilltree.clickNode, mouseOverNode)
          return nil
        end
      end
      if self:captureMouse(btn) then
        self._dragged = false
      end
      skilltree.redraw()
    elseif btn == self:mouseCaptureButton() then
      if btn == 2 and not self._dragged then -- right click without dragging
        sfx "zoom"
        metagui.startEvent(function()
          zooming = true
          local z1 = skilltree.zoom
          local z2 = metagui.checkShift() and 0.25 or 0.5
          z2 = (z1 ~= z2) and z2 or 1.0
          local p = 0
          while true do
            p = math.min(p + 0.1, 1)
            skilltree.setZoom(util.lerp(p^0.5, z1, z2))
            if p >= 1 then -- finish step
              -- round scroll position to integer
              skilltree.scrollTo {math.floor(0.5 + scrollPos[1]), math.floor(0.5 + scrollPos[2]) }
              zooming = false
              return
            end
            coroutine.yield()
          end
        end)
      end
      self:releaseMouse()
      skilltree.redraw()
    end
  end
  
  function w:onCaptureMouseMove(d)
    if d[1] ~= 0 or d[2] ~= 0 then
      if vec2.mag(vec2.sub(metagui.mousePosition, self:mouseCapturePoint())) >= 5 then self._dragged = true end
      skilltree.scroll(vec2.mul(d, {-1, 1}))
    end
  end
  
  function w:isWheelInteractable() return true end
  function w:onMouseWheelEvent(dir)
    if zooming then return end -- block wheel zoom during smooth zoom
    local amt = dir < 0 and 2 or 0.5
    local mdiff = vec2.sub(self:relativeMousePosition(), vec2.mul(self.size, 0.5))
    
    -- set zoom, centered on cursor
    skilltree.scrollTo(vec2.add(scrollPos, mdiff))
    skilltree.setZoom(util.clamp(skilltree.zoom * amt, 0.25, 1))
    skilltree.scrollTo(vec2.sub(scrollPos, mdiff))
  end
end
