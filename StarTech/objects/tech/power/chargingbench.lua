--

require "/lib/stardust/power.item.lua"

shared.energyReceptor = {}

function shared.energyReceptor:receive(socket, amount, testOnly) -- this is already implemented in stardustlib :D
  return power.fillContainerEnergy(entity.id(), amount, testOnly)
end

--
