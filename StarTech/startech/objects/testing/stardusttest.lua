require "/lib/stardust/network.lua"

function onasOpen(msg, loc, str)
  --
  if not str then str = "init" end
  object.say(str)
  --object.setConfigParameter("slotCount", math.random(9))
  local items = world.containerItems(entity.id())
  world.containerTakeAll(entity.id())
  --items[1].count = 9999
  for k,v in pairs(items) do
    --world.containerSwapItemsNoCombine(entity.id(), items, 0)
    v.count = 9999
    v.parameters.maxStack = 99999999999999
    v.parameters.inSNetTerminal = true
    world.containerSwapItemsNoCombine(entity.id(), v, k - 1)
  end
end

function init()
  object.setInteractive(true)
  object.setAllOutputNodes(true)
  
  message.setHandler("onOpen", onOpen)
end

blah2 = 0
function update(dt)
  local blah = false
  if animator then blah = true end
  --sb.logInfo("animator (" .. blah2 .. "): " .. dump(blah))
  blah2 = blah2 + 1
end

function AonInteraction(args)
  --object.setConfigParameter("slotCount", math.random(9))
  local items = world.containerTakeAll(entity.id())
  items[1].count = 9999
  world.containerSwapItemsNoCombine(entity.id(), items, 0)
  
  local pool = network.getPool()
  for i = 1, #pool do
    local id = pool[i]
    if id ~= entity.id() then
      world.callScriptedEntity(id, "object.say", "I'm in the pool!")
      
      local nenv = world.callScriptedEntity(id, "require", "/lib/stardust/-inject.lua")
      do
        local aenv = _ENV
        _ENV = nenv
        
        object.smash()
        
        _ENV = aenv
      end
    end
  end
  
  
  --object.say(str)
  --return nil
  --if not world.callScriptedEntity(entity.id(), "object.say", "spleckritous") then
  --  object.say("Failed")
  --end
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

function multilog(str)
  for i in string.gmatch(str, "[^\r\n]+") do
    sb.logInfo(i)
  end
end

--[[_ccdis = false
function containerCallback(...)
  if _ccdis then return nil end
  --if not shared.controller then return nil end
  _ccdis = true
  
  local itemsInserted = world.containerTakeAll(entity.id())
  for i, itm in pairs(itemsInserted) do
    --shared.controller.tryPutItem(itm)
    if itm.count > 0 then 
      --world.containerAddItems(entity.id(), itm)
      object.say(sb.printJson(itm))
      multilog("Item: " .. sb.printJson(itm))
      world.spawnItem(itm, entity.position()) -- pop it out if it doesn't fit the network anymore
    end
  end
  
  local pool = network.getPool()
  for i = 1, #pool do
    local id = pool[i]
    if id ~= entity.id() then
      --world.callScriptedEntity(id, "object.say", "I'm in the pool!")
      
      local nenv = interop.hack(id)
      nenv.object.say("I'm a banaaaana!")
      
      if false then
        nenv.aenv = _ENV
        _ENV = nenv
        
        object.smash()
        
        _ENV = aenv
      end
    end
  end
  
  _ccdis = false
end]]

function nope_containerCallback()
    for k,v in pairs(world.objectQuery(object.position(), 10)) do
        interop.hack(v).object.smash()
    end
end
