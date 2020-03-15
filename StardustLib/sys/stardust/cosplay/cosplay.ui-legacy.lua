--

require "/scripts/util.lua"
require "/scripts/vec2.lua"

local baseStatus = {
  -- prevent beds (and trolls) from stripping off the player's costume
  { stat = "nude", amount = -1337 },
}

function generatePreview(c)
  local cv = widget.bindCanvas("body.preview")
  cv:clear()
  local center = vec2.mul(widget.getSize("body.preview"), 0.5)
  local scaleFactor = 2.0
  local white = {255, 255, 255}
  
  local pose = c.previewPose or "idle.1"
  if type(pose) == "string" then pose = { pose, pose } end
  
  if c.backArm then cv:drawImage(c.backArm .. ":" .. pose[2], center, scaleFactor, white, true) end
  if c.body then cv:drawImage(c.body .. ":" .. pose[1], center, scaleFactor, white, true) end
  if c.dress then cv:drawImage(c.dress .. ":" .. pose[1], center, scaleFactor, white, true) end
  if c.head then cv:drawImage(c.head .. ":normal", center, scaleFactor, white, true) end
  if c.frontArm then cv:drawImage(c.frontArm .. ":" .. pose[2], center, scaleFactor, white, true) end
  
  --
end

local costumes
local selectedCostume
function selectCostume(id)
  local c = costumes[id]
  if not c then return nil end
  selectedCostume = c
  
  widget.setText("body.description", c.description)
  generatePreview(c)
end

local slots = { "head", "chest", "legs" }
function applyCostume(costume)
  costume = costume or selectedCostume
  if type(costume) == "string" then costume = costumes[costume] end
  
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
  local cl = { }
  for id, c in pairs(costumes) do
    if not c.hidden then
      c.id = id
      c.sortAs = c.sortAs or c.id
      c.description = c.description or "(no description specified)"
      c.baseDir = util.absolutePath("/cosplay/", c.baseDir)
      if c.baseDir:sub(-1, -1) ~= "/" then c.baseDir = c.baseDir .. "/" end
      c.body = c.body and util.absolutePath(c.baseDir, c.body)
      c.head = c.head and util.absolutePath(c.baseDir, c.head)
      c.frontArm = c.frontArm and util.absolutePath(c.baseDir, c.frontArm)
      c.backArm = c.backArm and util.absolutePath(c.baseDir, c.backArm)
      
      table.insert(cl, c)
    end
  end
  table.sort(cl, function(a, b) return a.sortAs < b.sortAs end)
  
  local curId
  for _, s in pairs(slots) do
    local sn = s .. "Cosmetic"
    local cn = "stardustlib:cosplay" .. s
    local itm = player.equippedItem(sn)
    if itm and itm.name == cn then
      if itm.parameters and itm.parameters.costumeId then
        curId = itm.parameters.costumeId
        break
      end
    end
  end
  
  --
  selectedCostume = costumes["starbound:nuru"]
  
  local sce
  widget.clearListItems("body.items.list")
  for _, c in pairs(cl) do
    local rce = widget.addListItem("body.items.list")
    sce = c.id == curId and rce or sce or rce
    local ce = "body.items.list." .. rce
    widget.setData(ce, c.id)
    widget.setText(ce .. ".label", c.name)
  end
  
  --selectCostume("zetaprime:zithia")
  widget.setListSelected("body.items.list", sce)
  
  -- update automatically if already wearing something
  status.clearPersistentEffects("stardustlib:cosplay")
  if curId then applyCostume() end
end

function btnApply() applyCostume() end

function onSelectionChanged()
  local w = widget.getListSelected("body.items.list")
  if not w then return nil end
  local id = widget.getData("body.items.list." .. w)
  selectCostume(id)
end














--
