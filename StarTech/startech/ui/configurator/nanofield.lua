--
require "/sys/stardust/skilltree/skilltree.lua"

local function loadItem()
  local nf = player.equippedItem("chest")
  if (nf or { }).name ~= "startech:nanofield" then return pane.dismiss() end
  return nf
end

local function saveItem(itm)
  do -- all we need to modify from the current item is the skill tree data
    local c = player.equippedItem("chest")
    c.parameters["stardustlib:skillData"] = itm.parameters["stardustlib:skillData"]
    itm = c
  end
  
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
    --{ stat = "healthRegen", amount = 1 },
    { stat = "grit", amount = calc(skillData.stats.grit) },
    { stat = "stardustlib:leech", amount = calc(skillData.stats.leech) },
    { stat = "stardustlib:bloodthirst", amount = calc(skillData.stats.bloodthirst) },
  })
  util.appendLists(stats, skillData.effects) -- carry over node status effects
  itm.parameters.statusEffects = stats
  
  -- apply FP capacity
  if not itm.parameters.batteryStats then itm.parameters.batteryStats = { } end
  local fpc = math.ceil(calc(skillData.stats.powerCapacity))
  if fpc == 0 then fpc = nil end -- just don't specify if missing
  itm.parameters.batteryStats.capacity = fpc
  
  player.setEquippedItem("chest", itm)
end

function init()
  debugAP:setVisible(player.isAdmin())
  skilltree.initFromItem(treeCanvas, loadItem, saveItem)
  pane.playSound "/sfx/objects/outpostbutton.ogg"
end

function apply:onClick() skilltree.applyChanges() end
function reset:onClick()
  if player.isAdmin() and metagui.checkShift() then
    return skilltree.refundAll()
  end
  skilltree.resetChanges()
end

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

local function hideWhenZero(txt, v) if v == 0 then return "" end end
local function hideWhenOne(txt, v) if v == 1 then return "" end end

function skilltree.modifyStatDisplay.armor(txt, v)
  local dr = 1.0 - (.5 ^ (v / 100))
  dr = math.floor(dr*10000+0.5)/10000 -- limit to two decimal places
  return txt .. string.format(" ^lightgray;(%s damage reduction)^reset;", skilltree.displayNumber(dr, true))
end
function skilltree.modifyStatDisplay.healthRegen(txt, v)
  if v == 0 then return "" end
  return txt .. " ^lightgray;per second^reset;"
end
function skilltree.modifyStatDisplay.leech(txt, v)
  if v == 0 then return "" end
  return string.format("%s ^lightgray;of damage dealt ^cyan;leeched as health^reset;", skilltree.displayNumber(v, true))
end
function skilltree.modifyStatDisplay.bloodthirst(txt, v)
  if v == 0 or not status.statusProperty("stardustlib:hungerEnabled") then return "" end
  return string.format("%s ^lightgray;of damage dealt ^cyan;leeched as hunger^reset;", skilltree.displayNumber(v, true))
end

function skilltree.modifyStatDisplay.powerCapacity(txt, v)
  return string.format("%s^cyan;FP capacity^reset;", skilltree.displayNumber(math.ceil(v)))
end

skilltree.modifyStatDisplay.grit = hideWhenZero
skilltree.modifyStatDisplay.wingDamage = hideWhenOne

function update()
  -- canary
  local function nope() --[[] ]skilltree.playSound "reset"--[[]] pane.dismiss() end
  local itm = player.equippedItem("chest")
  if not itm or itm.name ~= "startech:nanofield" then return nope() end
  local sd = itm.parameters["stardustlib:skillData"]
  if not sd then return nope() end
  if sd.uuid ~= skilltree.uuid then return nope() end
end
