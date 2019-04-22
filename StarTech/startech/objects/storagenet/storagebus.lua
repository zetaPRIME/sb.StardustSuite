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

storageProvider = {}
shared.storageProvider = storageProvider

function init()
  if not storage.orientation then storage.orientation = 1 end
  if not storage.priority then storage.priority = 0 end
  
  storageProvider.entityId = entity.id
  --storageProvider.uid = math.random(-99999999, 99999999)
  object.setInteractive(false)
  message.setHandler("wrenchInteract", onWrench)
  
  message.setHandler("getInfo", uiGetInfo)
  message.setHandler("setInfo", uiSetInfo)
  
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
    local dl = {"v","<","^",">"}
    storage.orientation = (storage.orientation % 4) + 1
    object.setAnimationParameter("orientation", storage.orientation)
    object.say(dl[storage.orientation])
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

function sendItems()
  if not shared.controller then return {} end
  return shared.controller:listItems()
end

function onStorageNetUpdate()
  -- save memory by sharing a single cache among all things that have touched since last unload!
  itemutil.mergeConfigCache(shared.controller.id)
end

-- storage interface:
-- getStoragePriority() -- returns an (integer?) priority value
-- getItemList() -- exactly how world.containerItems() returns, I guess
-- tryTakeItem(?)
-- tryPutItem(?)

priorityModifier = 1000000
function storageProvider:getPriority(item)
  local priorityMod = 0
  
  if storage.filter then priorityMod = priorityModifier * 2 end -- any filter sets "go here first!"
  if item then
    local spos = vec2.add(entity.position(), orientations[storage.orientation])
    local sid = world.objectAt(spos)
    if sid and world.containerSize(sid) then
      local itemAnon = {
        name = item.name,
        count = 1,
        parameters = item.parameters
      }
      if world.containerAvailable(sid, itemAnon) > 0 then priorityMod = priorityMod + priorityModifier end
      --if storage.filter and itemutil.matchFilter(storage.filter, item) then priorityMod = priorityMod + priorityModifier * 2 end -- yep
    end
  end--else
  
  --sb.logInfo(table.concat({ "entity ", entity.id(), " priority ", basePriority + priorityMod }))
  return storage.priority + priorityMod
end

function storageProvider:getItemList()
  local spos = vec2.add(entity.position(), orientations[storage.orientation])
  local sid = world.objectAt(spos)
  --sb.logInfo(table.concat({ "spos: ", dump(spos), " sid: ", sid }))
  if not sid then return {} end
  return world.containerItems(sid) or {}
end

function storageProvider:tryTakeItem(itemReq)
  local itemReqAnon = {
    name = itemReq.name,
    count = 1,
    parameters = itemReq.parameters
  }
  
  local spos = vec2.add(entity.position(), orientations[storage.orientation])
  local sid = world.objectAt(spos)
  if not (sid and world.containerSize(sid)) then return nil end
  if world.containerAvailable(sid, itemReqAnon) == 0 then return nil end
  
  local count = 0
  local remaining = itemReq.count
  for i, itm in pairs(world.containerItems(sid)) do
    if itemutil.canStack(itm, itemReq) then
      local take = world.containerTakeNumItemsAt(sid, i-1, math.min(itm.count, remaining))
      count = count + take.count
      remaining = remaining - take.count
      if remaining <= 0 then break end
    end
  end
  itemReq.count = remaining
  
  itemReqAnon.count = count -- reuse this because why not
  return itemReqAnon
end

function storageProvider:tryPutItem(item)
  local spos = vec2.add(entity.position(), orientations[storage.orientation])
  local sid = world.objectAt(spos)
  if not (sid and world.containerSize(sid)) then return nil end
  
  if storage.filter then
    if not itemutil.matchFilter(storage.filter, item) then return nil end -- don't bother if filtered
  end
  
  local leftover = world.containerAddItems(sid, item)
  if leftover then item.count = leftover.count else item.count = 0 end -- hopefully safe...
end
