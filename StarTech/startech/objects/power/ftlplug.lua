--

require "/lib/stardust/power.lua"

shared.energyReceptor = { }

function init()
  rate = config.getParameter("conversionRate")
end

function shared.energyReceptor:receive(socket, amount, testOnly)
  local fuel = world.getProperty("ship.fuel")
  local maxFuel = world.getProperty("ship.maxFuel")
  if type(fuel) ~= "number" or type(maxFuel) ~= "number" then return 0 end -- inactive on non-ship worlds
  local result = math.min(amount, (maxFuel - fuel) * rate)
  if not testOnly then -- commit
    world.setProperty("ship.fuel", math.min(fuel + (result / rate), maxFuel))
  end
  return result
end

--
