require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/itemutil.lua"

orientations = {
  { 0, -1 },
  { -1, 0 },
  { 0, 1 },
  { 1, 0 }
}
orientName = { "down", "left", "up", "right" }

maxSpeedUpgrades = 5
rates = {
  30, 15, 8, 4, 2, 1
}
function updateRates()
  idleRate = 60
  drawRate = rates[1+cfg.speedUpgrades]
end

function init()
  if not storage.orientation then storage.orientation = 1 end
  storage.cfg = storage.cfg or { } ; cfg = storage.cfg
  cfg.speedUpgrades = cfg.speedUpgrades or 0
  updateRates()
  script.setUpdateDelta(drawRate)
  
  object.setInteractive(false)
  message.setHandler("wrenchInteract", onWrench)
  
  message.setHandler("uiUpdate", uiUpdate)
  
  object.setAnimationParameter("orientation", storage.orientation)
end

function onWrench(msg, isLocal, player, shiftHeld)
  if shiftHeld then
    return {
      interact = {
        id = entity.id(),
        type = config.getParameter("interactAction"),
        config = config.getParameter("interactData")
      }
    }
  else
    storage.orientation = (storage.orientation % 4) + 1
    object.setAnimationParameter("orientation", storage.orientation)
    --local dl = {"v","<","^",">"}
    --object.say(dl[storage.orientation])
  end
end

function uiGetInfo() return { filter = storage.filter or "", priority = storage.priority } end
function uiSetInfo(msg, isLocal, filter, priority)
  storage.priority = priority
  local pr = "Priority set: " .. storage.priority .. "\n"
  if filter == "" then
    storage.filter = nil
    object.say(pr .. "Filter cleared")
  else
    storage.filter = filter
    object.say(pr .. "Filter set: " .. filter)
  end
end

function uiUpdate(msg, isLocal, t)
  t = t or { } -- safety
  -- merge sent config
  for k,v in pairs(t.cfg or { }) do cfg[k] = v end
  
  -- special commands (item-sync security etc.)
  for cmd, param in pairs(t.cmd or { }) do
    
  end
  
  updateRates()
  return cfg
end

function match(item)
  if not cfg.matchItem then return true end -- success if no match set
  if item.name ~= cfg.matchItem.name then return false end -- fail if not the same item
  return cfg.matchFuzzy or itemutil.canStack(item, cfg.matchItem)
end

function update(dt)
  script.setUpdateDelta(idleRate) -- set delta to idle delay, then set back to configured delta if successful
  if not shared.controller then return end -- abort if not connected
  local numDraw = cfg.stackUpgrade and 99999 or 1
  
  local spos = vec2.add(entity.position(), orientations[storage.orientation])
  local sid = world.objectAt(spos) or entity.id()
  
  local slots = world.containerSize(sid) or 0
  if slots < 1 then return end
  
  local idle = true
  local contents = world.containerItems(sid)
  for i=1,slots do
    local itm = contents[i]
    if itm and match(itm) then
      local iitm = { name = itm.name, count = math.min(numDraw, itm.count), parameters = itm.parameters }
      local bcount = iitm.count
      shared.controller:tryPutItem(iitm)
      if iitm.count < bcount then
        idle = false
        world.containerTakeNumItemsAt(sid, i-1, bcount - iitm.count)
        break
      end
    end
  end
  
  if idle then return end
  script.setUpdateDelta(drawRate) -- reset delta
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function containerCallback(...)
  --
end

function sendItems()
  if not shared.controller then return {} end
  return shared.controller:listItems()
end

function onStorageNetUpdate()
  -- save memory by sharing a single cache among all things that have touched since last unload!
  itemutil.mergeConfigCache(shared.controller.id)
end
