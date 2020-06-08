--
require "/sys/stardust/skilltree/skilltree.lua"

local function loadItem()
  local nf = player.equippedItem("chest")
  if (nf or { }).name ~= "startech:nanofield" then return pane.dismiss() end
  return nf
end

local function saveItem(itm)
  local c = player.equippedItem("chest")
  itm.parameters.batteryStats = c.parameters.batteryStats or { } -- retain energy levels
  
  -- apply stats
  local skillData = itm.parameters["stardustlib:skillData"]
  local calc = skilltree.calculateFinalStat
  local stats = { }
  util.appendLists(stats, itemutil.baseProperty(itm, "statusEffects"))
  util.appendLists(stats, {
    { stat = "protection", amount = calc(skillData.stats.armor) },
    { stat = "maxHealth", amount = calc(skillData.stats.health) - 100 },
    { stat = "maxEnergy", amount = calc(skillData.stats.energy) - 100 },
    { stat = "powerMultiplier", baseMultiplier = calc(skillData.stats.damage) },
  })
  itm.parameters.statusEffects = stats
  
  player.setEquippedItem("chest", itm)
end

function init()
  skilltree.initFromItem(treeCanvas, loadItem, saveItem)
end

function apply:onClick() skilltree.applyChanges() end
function reset:onClick() skilltree.resetChanges() end

if debugAP then
  function debugAP:onEnter()
    status.setStatusProperty("stardustlib:ap", tonumber(debugAP.text))
    skilltree.recalculateStats()
  end
end

function toggleStats:onClick()
  sidebarContainer:setVisible(not sidebarContainer.visible)
  self:setText(sidebarContainer.visible and "<" or ">")
end

function skilltree.modifyStatDisplay.armor(txt, v)
  local dr = 1.0 - (.5 ^ (v / 100))
  dr = math.floor(dr*10000+0.5)/10000 -- limit to two decimal places
  return txt .. string.format(" ^lightgray;(%s damage reduction)^reset;", skilltree.displayNumber(dr, true))
end

function update()
  -- canary
  local function nope() skilltree.playSound "reset" pane.dismiss() end
  local itm = player.equippedItem("chest")
  if not itm or itm.name ~= "startech:nanofield" then return nope() end
  local sd = itm.parameters["stardustlib:skillData"]
  if not sd then return nope() end
  if sd.uuid ~= skilltree.uuid then return nope() end
end
