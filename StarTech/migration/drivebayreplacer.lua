params = nil
tried = 0

function update()
  if params then
    tried = tried + 1
    if world.placeObject("startech:storagenet.drivebay", params.pos, params.dir) then
      local sid = world.objectAt(params.pos)
  
      for k,v in pairs(params.itm) do
        world.containerSwapItems(sid, v, k - 1)
      end
      
      stagehand.die()
    elseif tried >= 60 then -- abort - structure is gone; just pop off instead
      for k,v in pairs(params.itm) do
        world.spawnItem(v, params.pos)
      end
      world.spawnItem({count=1, name="startech:storagenet.drivebay"}, params.pos)
      
      stagehand.die()
    end
  end
end

function setupReplace(par) params = par end
