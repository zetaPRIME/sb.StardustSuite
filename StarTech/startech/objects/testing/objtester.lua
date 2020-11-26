--

local onShip

local function getData(k)
  return root.itemConfig({name = "stardustlib:datastore", count = 1, parameters = { dataRequest = { [k] = true } } }).parameters.dataReturn[k]
end
local function setData(k, v)
  root.itemConfig({name = "stardustlib:datastore", count = 1, parameters = { dataInsert = { [k] = v } } })
end

function init()
  object.setInteractive(true)
  onShip = not not world.getProperty("ship.fuel")
  if onShip then setData("shipIsLoaded", true) end
end

function uninit()
  if onShip then setData("shipIsLoaded", false) end
end

function onInteraction()
  local theCount = (getData "theCount" or 0) + 1
  setData("theCount", theCount)
  
  object.say("The count is: " .. theCount .. "\n" .. (getData "shipIsLoaded" and "ship is loaded" or "ship is not loaded"))
end

function update()
  if onShip then
    local pos = world.entityPosition(entity.id())
    world.loadRegion{pos[1] - 1, pos[2] - 1, pos[1] + 1, pos[2] + 1}
  end
end
