--
require "/scripts/util.lua"

require "/lib/stardust/network.lua"
require "/lib/stardust/tasks.lua"
--require "/lib/stardust/itemutil.lua"

local processes = taskQueue()

local deviceMap = { } -- map<objId, list<device>>

local itemCache = { }

--[[
  cache structure:
  itemname = {
    types = {
      [1] = {
        descriptor = <item descriptor>
        
      }
      ...
    }
  }
]]

function init()
  
  object.setInteractive(false) -- disable container interface
  
  -- set all outputs positive for chunkloading purposes
  for i=1, object.outputNodeCount() do object.setOutputNodeLevel(i-1, true) end
  
end

function update(dt)
  processes:run()
end

processes:spawn("networkManager", function()
  --
  local pool
  
  while true do
    local old = pool
    pool = network.getPool(nil, "startech:storagenet")
    local delta = pool:delta(old)
    
    
    util.wait(5)
  end
end)
