--

require "/scripts/util.lua"

local costumes
local selectedCostume
function selectCostume(id)
  local c = costumes[id]
  if not c then return nil end
  selectedCostume = c
  
  widget.setText("body.description", c.description)
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
    itm = { name = cn, count = 1, parameters = { hideBody = true } }
    if s == "head" then
      itm.parameters.frames = costume.head or "/sys/stardust/cosplay/blank.png"
    elseif s == "chest" then
      itm.parameters.frames = { frontSleeve = costume.frontArm, backSleeve = costume.backArm }
    else -- legs
      itm.parameters.frames = costume.body or "/sys/stardust/cosplay/blank.png"
    end
    player.setEquippedItem(sn, itm)
    
  end
  
end

function init()
  local cdata = root.assetJson("/cosplay/costumes.json")
  costumes = cdata.costumes
  local cl = { }
  for id, c in pairs(costumes) do
    c.id = id
    c.sortAs = c.sortAs or c.id
    c.description = c.description or "(no description specified)"
    c.baseDir = util.absolutePath("/cosplay/", c.baseDir)
    c.body = c.body and util.absolutePath(c.baseDir, c.body)
    c.head = c.head and util.absolutePath(c.baseDir, c.head)
    c.frontArm = c.frontArm and util.absolutePath(c.baseDir, c.frontArm)
    c.backArm = c.backArm and util.absolutePath(c.baseDir, c.backArm)
    
    table.insert(cl, c)
  end
  table.sort(cl, function(a, b) return a.sortAs < b.sortAs end)
  
  --
  selectedCostume = costumes["starbound:nuru"]
  
  local sce
  widget.clearListItems("body.items.list")
  for _, c in pairs(cl) do
    local rce = widget.addListItem("body.items.list")
    sce = sce or rce
    local ce = "body.items.list." .. rce
    widget.setData(ce, c.id)
    widget.setText(ce .. ".label", c.name)
  end
  
  --selectCostume("zetaprime:zithia")
  widget.setListSelected("body.items.list", sce)
end

function btnApply() applyCostume() end

function onSelectionChanged()
  local w = widget.getListSelected("body.items.list")
  if not w then return nil end
  local id = widget.getData("body.items.list." .. w)
  selectCostume(id)
end














--
