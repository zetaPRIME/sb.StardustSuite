-- StardustLib Costume UI

local baseStatus = {
  -- prevent beds (and trolls) from stripping off the player's costume
  { stat = "nude", amount = -1337 },
}

function generatePreview(w, costume, scale)
  local c = widget.bindCanvas(w.backingWidget) c:clear()
  local center = vec2.mul(w.size, 0.5)
  local pose = costume.previewPose or "idle.1"
  if type(pose) == "string" then pose = { pose, pose } end
  
  if costume.backArm then c:drawImage(costume.backArm .. ":" .. pose[2], center, scale, nil, true) end
  if costume.body then c:drawImage(costume.body .. ":" .. pose[1], center, scale, nil, true) end
  if costume.dress then c:drawImage(costume.dress .. ":" .. pose[1], center, scale, nil, true) end
  if costume.head then c:drawImage(costume.head .. ":normal", center, scale, nil, true) end
  if costume.frontArm then c:drawImage(costume.frontArm .. ":" .. pose[2], center, scale, nil, true) end
end

local costumes
local currentCostume

local slots = { "head", "chest", "legs" }
function applyCostume(costume)
  costume = costume or currentCostume
  if type(costume) == "string" then costume = costumes[costume] end
  if not costume then return nil end
  
  for _, s in pairs(slots) do
    local sn = s .. "Cosmetic"
    local cn = "stardustlib:cosplay" .. s
    
    -- give back cosmetic items that aren't costume pieces
    local itm = player.equippedItem(sn)
    if itm and itm.name ~= cn then player.giveItem(itm) end
    
    -- generate and apply item
    itm = { name = cn, count = 1, parameters = { hideBody = true, costumeId = costume.id, description = string.format("^lightgray;Costume %s - ^white;%s^reset;", s:gsub("^%l", string.upper), costume.name) } }
    if s == "head" then
      itm.parameters.frames = costume.head or "/sys/stardust/cosplay/blank.png"
    elseif s == "chest" then
      itm.parameters.frames = { frontSleeve = costume.frontArm, backSleeve = costume.backArm, body = costume.dress }
    else -- legs
      itm.parameters.frames = costume.body or "/sys/stardust/cosplay/blank.png"
    end
    player.setEquippedItem(sn, itm)
  end
  
  -- set up costume-related status
  status.setPersistentEffects("stardustlib:cosplay", util.mergeLists(baseStatus, costume.status or { }))
end

function init()
  local cdata = root.assetJson("/cosplay/costumes.json")
  costumes = cdata.costumes
  for id, c in pairs(costumes) do -- normalize information
    c.id = id
    c.sortAs = c.sortAs or c.id
    c.description = c.description or "(no description specified)"
    c.baseDir = util.absolutePath("/cosplay/", c.baseDir)
    if c.baseDir:sub(-1, -1) ~= "/" then c.baseDir = c.baseDir .. "/" end
    c.body = c.body and util.absolutePath(c.baseDir, c.body)
    c.head = c.head and util.absolutePath(c.baseDir, c.head)
    c.frontArm = c.frontArm and util.absolutePath(c.baseDir, c.frontArm)
    c.backArm = c.backArm and util.absolutePath(c.baseDir, c.backArm)
    
  end
  
  -- find currently worn costume if applicable
  for _, s in pairs(slots) do
    local sn = s .. "Cosmetic"
    local cn = "stardustlib:cosplay" .. s
    local itm = player.equippedItem(sn)
    if itm and itm.name == cn then
      if itm.parameters and itm.parameters.costumeId then
        currentCostume = itm.parameters.costumeId
        break
      end
    end
  end
  
  buildList()
  
  -- update automatically if already wearing something
  status.clearPersistentEffects("stardustlib:cosplay")
  if currentCostume then applyCostume() end
end

local function onCostumeSelected(w)
  currentCostume = w.costume
  local c = currentCostume and costumes[currentCostume]
  if not c then return nil end
  
  generatePreview(preview, c, 2.0)
  descLabel:setText(c.description)
  descArea:scrollBy{0, 10000}
  paneBase:applyGeometry()
end

function buildList()
  local cl = { }
  for _, c in pairs(costumes) do if not c.hidden then table.insert(cl, c) end end
  table.sort(cl, function(a, b) return a.sortAs < b.sortAs end)
  
  local ccl
  
  -- actually build
  costumeList:clearChildren()
  for _, c in pairs(cl) do
    local li = costumeList:addChild { type = "listItem" }
    local pvw = li:addChild { type = "canvas", size = {22, 22}, mouseTransparent = true }
    local l = li:addChild { type = "label", text = c.name, expand = true }
    li.costume = c.id
    li.onSelected = onCostumeSelected
    
    generatePreview(pvw, c, 0.5)
    if c.id == currentCostume then ccl = li end
  end
  
  if ccl then ccl:select() end
end

function apply:onClick() applyCostume() end
