require "/scripts/vec2.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/tasks.lua"

storagenet = { }
local prov

local provider = { }

function storagenet:onConnect()
  object.say "connected!"
  prov = storagenet:registerStorage(provider)
end

function storagenet:onDisconnect()
  object.say "disconnected."
end

function provider:onConnect()
  self:updateItemCounts(world.containerItems(entity.id()))
end

local svc = { }

function dbg(txt)
  sb.logInfo(txt)
  object.say(txt)
end

function svc.listItems()
  if not storagenet.connected then return { } end
  if false then
    return { { name = "copperore", count = 23, parameters = { } } }
  end
  --
  local lst = { }
  for id, e in pairs(storagenet.tmpCache) do
    for v in e:iterate() do
      --dbg("found item " .. v.descriptor.name .. " of count " .. v.descriptor.count)
      if v.descriptor.count > 0 then table.insert(lst, v.descriptor) end
      --lst[tostring(v.descriptor)] = v.descriptor.count > 0 and v.descriptor or nil
    end
  end
  return lst
end

function svc.updateItems()
  return svc.listItems()
end

-- -- --

function init()
  for k, v in pairs(svc) do message.setHandler(k, v) end
end

function containerCallback()
  if not storagenet.connected then return end
  prov:clearItemCounts()
  prov:updateItemCounts(world.containerItems(entity.id()))
end
