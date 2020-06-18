--

require "/lib/stardust/power.lua"

function init()
  -- set all outputs positive for chunkloading purposes
  for i=1, object.outputNodeCount() do object.setOutputNodeLevel(i-1, true) end
end

function update(dt)
  power.sendEnergy(0, 573000000)
end
