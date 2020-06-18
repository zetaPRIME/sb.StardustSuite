--

require "/lib/stardust/power.lua"

shared.energyReceptor = {}

function init()
  -- set all outputs positive for chunkloading purposes
  for i=1, object.outputNodeCount() do object.setOutputNodeLevel(i-1, true) end
end

local looping = false
function shared.energyReceptor:receive(socket, amount, testOnly)
  if looping then return 0 end -- an infinite loop here would be bad, mmkay?
  looping = true
  local result = power.sendEnergy(0, amount, testOnly) -- send directly on recieve
  looping = false
  return result
end

--
