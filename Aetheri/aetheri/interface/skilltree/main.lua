-- Aethyrium - skill tree(s) for the Aetheri

--[[ TODO:
  allow pulling currency items
  
  figure out how to work refunding a single node:
  takes an item (picked up in cursor) to refund, a la Orb of Regret
  to determine if refundable, check (recursively) if every connected taken node is connected to the others
  or rather, take a list of connected taken nodes and follow the tree starting with the first to see if connects to all others (and an origin)
  if not, check the remaining ones to see if they're connected to an origin
  when refunding, only add to the list of nodes pending refund
  
  - change nodetaken flag from true to a table of information, including spent ap, items and socketed jewel
  
  decorations
  ship nodes (unlock FTL travel from skill tree?)
  indicators for "more in this direction"; scroll bounds?
  eventually sort things into BSP to make drawing and cursor checking less silly
  
  jewel sockets; insert/remove jewel items to change what the socket does, PoE style
  item config contains the "grants" array
  (flag is replaced with the item descriptor if filled? or separate data for ease of refunding?)
  ^ keep track of which nodes are Actually Unlocked... or rather, switch over to a "nodes unconfirmed" system for cancelling (refundOnCancel, refundOnComplete)
--]]

require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/rect.lua"
require "/scripts/interp.lua"
require "/lib/stardust/itemutil.lua"
require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"

require "/sys/stardust/quickbar/conditions.lua"

-- modules
require "/aetheri/interface/skilltree/activeskills.lua"

sounds = {
  unlock = "/sfx/objects/ancientenergy_chord.ogg",
  cantUnlock = "/sfx/interface/clickon_error.ogg",
  confirm = "/sfx/objects/essencechest_open3.ogg",
  cancel = "/sfx/interface/nav_insufficient_fuel.ogg",
  
  jump = { "/sfx/interface/stationtransponder_stationpulse.ogg", "/sfx/tech/tech_dash.ogg" },
  
  socketJewel = "/sfx/melee/sword_parry.ogg", --"/sfx/objects/essencechest_open1.ogg",
  
  openSkillDrawer = "/sfx/objects/ancientenergy_pickup2.ogg",
  closeSkillDrawer = "/sfx/objects/ancientenergy_pickup1.ogg",
  selectSkill = "/sfx/objects/essencechest_open3.ogg",
}

directives = {
  nodeActive = "",
  nodeInactive = "",
}

function playSound(s)
  if type(s) == "string" then s = {s} end
  for _, s in pairs(s) do pane.playSound(s) end
end

function nf() end
view = nil

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

local function populateSkillData(node)
  local itm = { name = "aetheri:skill." .. node.skill, count = 1 }
  local icon = itemutil.property(itm, "inventoryIcon")
  node.icon = itemutil.relativePath(itm, type(icon) == "string" and icon or icon[#icon].image)
  node.name = itemutil.property(itm, "shortdescription")
  node.grants = node.grants or { }
  table.insert(node.grants, 1, {"description", itemutil.property(itm, "description")})
end

local modeHasIcon = { flat = true, increased = true, more = true }
local function setNodeVisuals(node)
  if upkeepOnly then return nil end -- skip if it won't be shown anyway
  
  -- icon
  if not node.icon then
    if node.type == "origin" then node.icon = "book.png"
    elseif node.type == "link" then node.icon = "link.png"
    elseif node.type == "gate" then
      node.icon = "gate-locked.png"
      node.unlockedIcon = "gate-unlocked.png"
    else -- automatically populate icon from the stats it grants
      local stat
      for _, g in pairs(node.grants or { }) do
        if modeHasIcon[g[1]] and statIcons[g[2]] then stat = g[2] break end
      end
      node.icon = statIcons[stat] or "misc1.png"
    end
  end
  node.icon = util.absolutePath("/aetheri/interface/skilltree/icons/", node.icon)
  node.unlockedIcon = node.unlockedIcon and util.absolutePath("/aetheri/interface/skilltree/icons/", node.unlockedIcon)
  
  if node.skill then populateSkillData(node) end
  if node.type == "link" then node.fixedCost = 0 end
  
  -- tool tip
  local tt = { }
  if node.name then table.insert(tt, string.format("^violet;%s^reset;\n", node.name)) end
  for _, g in pairs(node.grants or { }) do
    local mode, stat, amt = table.unpack(g)
    if mode == "description" then
      table.insert(tt, string.format("%s^reset;\n", stat))
    elseif mode == "flat" then
      table.insert(tt, string.format("%s^white;%s ^cyan;%s^reset;\n", amt >= 0 and "+" or "-", numStr(math.abs(amt)), statNames[stat] or stat))
    elseif mode == "increased" then
      table.insert(tt, string.format("^white;%s%%^reset; %s ^cyan;%s^reset;\n", numStr(math.abs(amt)*100), amt >= 0 and "increased" or "decreased", statNames[stat] or stat))
    elseif mode == "more" then
      table.insert(tt, string.format("^white;%s%%^reset; %s ^cyan;%s^reset;\n", numStr(math.abs(amt)*100), amt >= 0 and "more" or "less", statNames[stat] or stat))
    end
  end
  node.toolTip = table.concat(tt)
  if node.itemCost then -- assemble information for item requirement tooltips
    for _, d in pairs(node.itemCost) do
      d.displayName, d.rarity = itemutil.property(d, "shortdescription"), itemutil.property(d, "rarity") or "Common"
    end
  end
end

local trees = { }
function init()
  upkeepOnly = not not config.getParameter("upkeepOnly")
  -- take care of data work first
  do -- load in skill data
    local cfg = root.assetJson("/aetheri/species/skilltree.config")
    -- global stuffs
    compatId = cfg.compatId
    revId = cfg.revId
    statNames = cfg.statNames
    statIcons = cfg.statIcons
    baseStats = cfg.baseStats
    baseNodeCost = cfg.baseNodeCost
    
    activeSkills = cfg.activeSkills
    startingSkills = cfg.startingSkills
    startingLoadout = cfg.startingLoadout
    
    local t
    -- recursive function for loading in node data
    local iterateTree iterateTree = function(tree, pfx, offset)
      for k, n in pairs(tree) do
        local type = n.type or "node"
        local pos = vec2.add(n.position or {0, 0}, offset)
        local path = string.format("%s/%s", pfx, k)
        if type == "group" then
          -- group conditions; same format (and options) as quickbar ones!
          if not n.condition or condition(table.unpack(n.condition)) then --
            iterateTree(n.children or { }, path, pos)
          end
        else -- actual node
          local node = {
            tree = t, path = path, type = type,
            position = pos, connections = { },
            name = n.name, icon = n.icon, unlockedIcon = n.unlockedIcon,
            grants = n.grants, skill = n.skill, target = n.target or n.to,
            fixedCost = n.fixedCost, costMult = n.costMult, itemCost = n.itemCost,
            condition = n.condition,
          }
          if node.skill then -- automatic skill node shorthand
            node.grants = node.grants or { }
            table.insert(node.grants, { "unlockSkill", node.skill })
          end
          t.nodes[path] = node
          setNodeVisuals(node)
          if n.connectsTo and not upkeepOnly then -- premake connections (only when actually displaying)
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
  
  if upkeepOnly then return pane.dismiss() end
  
  widget.setItemSlotItem("skillslot1", {name="aetheri:skill.dig", count=1})
  widget.setItemSlotItem("skillslot2", {name="perfectlygenericitem", count=1})
  widget.setItemSlotItem("skillslot3", {name="perfectlygenericitem", count=1})
  widget.setItemSlotItem("skillslot4", {name="perfectlygenericitem", count=1})
  
  canvas = widget.bindCanvas("viewCanvas")
  view = nodeView.new(trees.passive)
  redrawCanvas()
end

function uninit()
  if changesToCommit() then
    playSound(sounds.cancel)
    refundItemCosts()
  end
end

function refundItemCosts()
  if playerTmpData and playerTmpData.itemsToConsume then
    -- refund consumed items
    for _, d in pairs(playerTmpData.itemsToConsume) do player.giveItem(d) end
    playerTmpData.itemsToConsume = { } -- and reset
  end
end

function loadPlayerData()
  refundItemCosts()
  playerTmpData = {
    apToSpend = 0,
    itemsToConsume = { }
  }
  playerData = status.statusProperty("aetheri:skillTreeData", nil)
  if not playerData or playerData.compatId ~= compatId then
    -- reset data
    local refundItems = playerData and playerData.itemsPendingRefund or { }
    if playerData then
      for _, tl in pairs(playerData.nodesUnlocked) do
        for _, nd in pairs(tl) do
          if type(nd) == "table" then
            status.setStatusProperty("aetheri:AP", status.statusProperty("aetheri:AP", 0) + (nd.spentAP or 0))
            util.appendLists(refundItems, nd.spentItems or { })
            if nd.jewel then table.insert(refundItems, nd.jewel) end
          end
        end
      end
      -- refund all legacy spent AP
      status.setStatusProperty("aetheri:AP", status.statusProperty("aetheri:AP", 0) + (playerData.spentAP or 0))
    end
    playerData = {
      compatId = compatId,
      nodesUnlocked = { },
      -- keep anything still unlocked in its place
      selectedSkills = playerData and playerData.selectedSkills or startingLoadout,
      itemsPendingRefund = util.mergeLists(refundItems, playerData.itemsSpent or { })
    }
  end
  playerData.revId = revId
  playerData.itemsPendingRefund = playerData.itemsPendingRefund or { }
  
  for _, t in pairs(trees) do
    playerData.nodesUnlocked[t.name] = playerData.nodesUnlocked[t.name] or { }
  end
  
  recalculateStats()
  committedSkillsUnlocked = playerData.skillsUnlocked
  committedSkillUpgrades = playerData.skillUpgrades
  
  -- grab visuals
  appearance = status.statusProperty("aetheri:appearance", { })
  directives.nodeActive = string.format("?border=1;%s;00000000", color.toHex(color.fromHsl{ appearance.coreHsl[1], appearance.coreHsl[2], 0.75, 0.75 }))
  
  -- process pending refunds
  for _, d in pairs(playerData.itemsPendingRefund) do
    player.giveItem(d) -- TODO: give an item packet instead, where you can take out each item individually
    -- or just pull back any items the player drops??
  end playerData.itemsPendingRefund = { }
  
  -- refresh view on reload
  if view then view.needsRedraw = true end
  commitPlayerData() -- always update after load
  
  refreshSkillSlots()
end

function recalculateStats()
  --playerData.calculatedStats = { }
  local stats, flags = { }, { }
  for stat, t in pairs(baseStats) do -- populate base stat values
    stats[stat] = {t[1] or 0, t[2] or 1, t[3] or 1}
  end
  
  playerData.skillsUnlocked = { }
  playerData.skillUpgrades = { }
  for _, skill in pairs(startingSkills) do playerData.skillsUnlocked[skill] = true end
  
  playerData.rawStatus = { }
  playerData.effects = { }
  playerData.numNodesTaken = { }
  for tn, lst in pairs(playerData.nodesUnlocked) do
    local count = 0
    for path, f in pairs(lst) do
      if f then
        local node = trees[tn].nodes[path]
        if node.type ~= "origin" and not node.fixedCost then 
          count = count + (node.costMult or 1)
        end
        for _, g in pairs(node.grants or { }) do
          local mode, stat, amt = table.unpack(g)
          if mode == "flat" and stats[stat] then stats[stat][1] = stats[stat][1] + amt
          elseif mode == "increased" and stats[stat] then stats[stat][2] = stats[stat][2] + amt
          elseif mode == "more" and stats[stat] then stats[stat][3] = stats[stat][3] * (1.0 + amt)
          elseif mode == "rawStatus" and stat then table.insert(playerData.rawStatus, stat)
          elseif mode == "effect" and stat then table.insert(playerData.effects, stat)
          elseif mode == "flag" then flags[stat] = true
          elseif mode == "unlockSkill" and stat then playerData.skillsUnlocked[stat] = true
          elseif mode == "skillUpgrade" and stat and amt then
            playerData.skillUpgrades[stat] = playerData.skillUpgrades[stat] or { }
            playerData.skillUpgrades[stat][amt] = (playerData.skillUpgrades[stat][amt] or 0) + (g[4] or 1)
          end --
        end
      end
    end
    playerData.numNodesTaken[tn] = count
  end
  
  playerData.selectedSkills = playerData.selectedSkills or { }
  local unl = committedSkillsUnlocked or playerData.skillsUnlocked
  for i = 1, 4 do
    local skill = playerData.selectedSkills[i] or "none"
    skill = unl[skill] and skill or "none"
    playerData.selectedSkills[i] = skill
  end
  
  playerData.calculatedStats = stats
  playerData.flags = flags
end

function changesToCommit() return not not playerTmpData.changed end

function commitPlayerData()
  recalculateStats()
  committedSkillsUnlocked = playerData.skillsUnlocked
  committedSkillUpgrades = playerData.skillUpgrades
  status.setStatusProperty("aetheri:skillTreeData", playerData)
  status.setStatusProperty("aetheri:AP", status.statusProperty("aetheri:AP", 0) - playerTmpData.apToSpend)
  playerTmpData.apToSpend = 0
  playerTmpData.itemsToConsume = { }
  playerTmpData.changed = false
  world.sendEntityMessage(player.id(), "aetheri:refreshStats")
  commitSkillSlots()
end

function currentAP()
  return status.statusProperty("aetheri:AP", 0) - playerTmpData.apToSpend
end

function nodeCost(node)
  if node.fixedCost then return node.fixedCost, true end
  local c = playerData.numNodesTaken[node.tree.name] or 0
  local mult = node.costMult or 1
  local acc = 0
  while mult > 0 do
    local m = math.min(1, mult)
    acc = acc + math.floor(0.5 + baseNodeCost * 2^(c/10) * m)
    c = c + m
    mult = mult - 1
  end return acc
end

function isNodeUnlocked(node)
  if node.type == "origin" then return { } end
  return playerData.nodesUnlocked[node.tree.name][node.path]
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

function tryItemCost(node, consume)
  if not node.itemCost then return true end
  for _, d in pairs(node.itemCost) do
    if not (player.hasCountOfItem(d, true) >= d.count) then return false end
  end
  if consume then
    for _, d in pairs(node.itemCost) do
      table.insert(playerTmpData.itemsToConsume, player.consumeItem(d, false, true))
    end
  end
  return true
end

function tryUnlockNode(node)
  if not canUnlockNode(node) then return false end
  if not tryItemCost(node, true) then return false end
  if node.condition and not condition(table.unpack(node.condition)) then return false end
  local cost = nodeCost(node)
  playerData.nodesUnlocked[node.tree.name][node.path] = {
    spentAP = cost,
    spentItems = node.itemCost,
  }
  playerTmpData.apToSpend = playerTmpData.apToSpend + cost
  playerTmpData.changed = true
  recalculateStats()
  return true -- success!
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
  if changesToCommit() then playSound(sounds.confirm) end
  skillDrawer.close()
  commitPlayerData()
end
function btnCancel()
  if changesToCommit() then playSound(sounds.cancel) end
  skillDrawer.close()
  loadPlayerData()
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
  self.center = self.scroll
end

function nodeView:jumpTo(name)
  local node = self.tree.nodes[name]
  if not node then return nil end
  self.jump = { from = self.scroll, to = vec2.mul(node.position, self.nodeSpacing), time = 1.0 }
end

function nodeView:update()
  self.lastPos = self.lastPos or {0, 0}
  local pos = canvas:mousePosition()
  local forceRedraw = false
  
  if self.jump then
    if self.scrolling then self.lastPos = pos end -- no double-scroll
    self.jump.time = self.jump.time - script.updateDt() * 5.0
    local tween = interp.cos(util.clamp(self.jump.time, 0.0, 1.0), 1.0, 0.0)
    self.scroll = vec2.add( vec2.mul(self.jump.from, tween), vec2.mul(vec2.sub(pos, self.jump.to), 1.0-tween) )
    self.needsRedraw = true
    if self.jump.time <= 0 then
      self.jump = nil
      if self.btnDown[0] then self.scrolling = 0 end
      forceRedraw = true -- force tool tip/hover update
    end
  end
  
  if forceRedraw or vec2.mag(vec2.sub(pos, self.lastPos)) > 0 then -- if mouse moved...
    --self.needsRedraw = true
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
  self.btnDown = self.btnDown or { }
  -- 0-2: left, middle, right
  if btn == 0 then -- left button
    if down then
      if self.hover then -- click on node
        if self.hover.type == "link" then
          self:jumpTo(self.hover.target)
          playSound(sounds.jump)
          self.scrolling = btn
          self.lastPos = pos --
        else
          -- try to unlock node
          if tryUnlockNode(self.hover) then
            self.needsRedraw = true
            playSound(sounds.unlock)
          elseif not isNodeUnlocked(self.hover) then
            playSound(sounds.cantUnlock)
          end
        end
      else self.scrolling = btn self.jump = nil end -- or scroll
    elseif self.scrolling == btn then self.scrolling = nil end
  elseif btn == 1 then -- middle button - overview/jump
    local c = vec2.mul(widget.getSize("viewCanvas"), 0.5)
    local scaleFactor = 3
    if down then
      self.jump = nil
      --self.scroll = vec2.mul(vec2.sub(vec2.mul(self.tree.nodes["/origin"].position, self.nodeSpacing), canvas:mousePosition()), -1.0)
      self.scroll = vec2.add(vec2.mul(vec2.sub(self.scroll, pos), 1/scaleFactor), pos)
      self.nodeSpacing = self.nodeSpacing / scaleFactor
      self.needsRedraw = true
    elseif self.btnDown[btn] then
      self.scroll = vec2.add(vec2.mul(vec2.sub(self.scroll, pos), scaleFactor), pos)
      self.needsRedraw = true
      self.nodeSpacing = self.nodeSpacing * scaleFactor
    end
  end
  
  self.btnDown[btn] = down
end

local border = {
  {-1, 0},
  {1, 0},
  {0, -1},
  {0, 1},
}
function nodeView:redraw()
  canvas:clear()
  
  -- draw guiding line
  --canvas:drawLine(canvas:mousePosition(), self.scroll, {255, 255, 255, 63}, 1)
  
  local toolTipWidth = 160
  
  local lco = {0, 0}--{-.5, -.5}
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
    local fb = active or node == self.hover
    local icon = active and node.unlockedIcon or node.icon
    local nodeDirectives = active and directives.nodeActive or directives.nodeInactive
    --canvas:drawImage("/aetheri/interface/skilltree/nodeBG.png:" .. (active and "active" or "inactive"), pos, 1, {255, 255, 255}, true)
    canvas:drawImage(icon .. nodeDirectives, pos, 1, fb and {255, 255, 255} or {191, 191, 191}, true)
  end
  if self.hover then -- tool tip!
    local ttPos = vec2.add(self:nodeDrawPos(self.hover), {12, 4})
    local tt = self.hover.toolTip
    if not isNodeUnlocked(self.hover) then
      if self.hover.itemCost then
        local ctt = { }
        local hasAll = true
        for _, d in pairs(self.hover.itemCost) do
          local has = player.hasCountOfItem(d, true) >= d.count
          hasAll = has and hasAll
          table.insert(ctt, string.format("- %s%d ^reset;%s%s^reset;\n", has and "^white;" or "^red;", d.count, has and rarityColors[d.rarity:lower()] or "^red;", d.displayName))
        end
        table.insert(ctt, 1, string.format("%sMaterial cost^reset;:\n", hasAll and "" or "^red;"))
        tt = tt .. table.concat(ctt)
      end
      local cost, fixed = nodeCost(self.hover)
      if cost > 0 then -- only display nonzero costs
        tt = string.format("%s%s: %s%d ^violet;AP^reset;\n", tt, fixed and "Fixed cost" or "Cost", currentAP() >= cost and "^white;" or "^red;", cost)
      end
    end
    local btt = tt:gsub("(%b^;)", "") -- strip codes for border
    for _, off in pairs(border) do
      canvas:drawText(btt, { position = vec2.add(ttPos, off), horizontalAnchor = "left", verticalAnchor = "top", wrapWidth = toolTipWidth }, 8, {0, 0, 0, 222})
    end
    canvas:drawText(tt, { position = ttPos, horizontalAnchor = "left", verticalAnchor = "top", wrapWidth = toolTipWidth }, 8, {191, 191, 191})
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
  -- short circuit: check if already hovering over something first
  if self.hover and vec2.mag(vec2.sub(pos, vec2.mul(self.hover.position, self.nodeSpacing))) <= 10 then return self.hover end
  for _, node in pairs(self.tree.nodes) do -- otherwise just iterate and check everything until something found
    if vec2.mag(vec2.sub(pos, vec2.mul(node.position, self.nodeSpacing))) <= 10 then return node end
  end
  return nil
end
























--
