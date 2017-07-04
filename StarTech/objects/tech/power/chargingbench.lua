--

require "/lib/stardust/power.item.lua"

shared.energyReceptor = {}

function shared.energyReceptor:receive(socket, amount, testOnly) -- returns amount successfully input
  --sb.logInfo("power insert attempt: " .. amount .. " " .. (testOnly and "true" or "false"))
  return power.fillContainerEnergy(entity.id(), amount, testOnly)
end

--
