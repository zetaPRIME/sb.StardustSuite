--

require "/lib/stardust/prefabs.lua"
require "/lib/stardust/power.lua"

nullItem = { name = "", count = 0, parameters = {} }

function init()
  slotConfig = config.getParameter("slotConfig")
  smelterConfig = config.getParameter("smelterConfig")
  recipes = { }
  
  local function accumulateRecipes(recipes, objectId)
    local obj = objectId and root.itemConfig({ name = objectId, count = 1, parameters = { } }).config or { }
    
    local rcpInclude = obj.recipeInclude or config.getParameter("recipeInclude") or { }
    if type(rcpInclude) ~= "table" then rcpInclude = { rcpInclude } end
    for k,inc in pairs(rcpInclude) do accumulateRecipes(recipes, inc) end
    
    local rcpList = obj.recipes or config.getParameter("recipes") or { }
    for inp,rcp in pairs(rcpList) do
      recipes[inp] = rcp
    end
  end
  
  accumulateRecipes(recipes)
  
  rateMult = smelterConfig.rateMultiplier or 1
  
  local cfg = config.getParameter("batteryStats")
  battery = prefabs.power.battery(cfg.capacity, cfg.ioRate):hookUp():autoSave()
  storage.smelting = storage.smelting or {}
  smelting = storage.smelting -- alias
  smelting.remaining = smelting.remaining or 0
  smelting.smeltTime = smelting.smeltTime or 1
  smelting.item = smelting.item or nullItem
  smelting.results = smelting.results or {}
  
  message.setHandler("uiSyncRequest", uiSyncRequest)
  
  rng = sb.makeRandomSource(os.time())
end

function update()
  -- handle fueling
  if smelting.remaining > 0 then
    if battery:consume(smelterConfig.powerPerTick) then
      smelting.remaining = smelting.remaining - 1
    end
  else
    script.setUpdateDelta(30)
    local remainingOutput = {}
    
    local numSlots = world.containerSize(entity.id())
    
    -- attempt to stack result items into output slots
    for _,item in pairs(smelting.results) do
      local remaining = { name = item.name, count = item.count, parameters = item.parameters }
      local stacks = world.containerItems(entity.id())
      
      -- try to stack first
      for slot = 1, numSlots do
        if stacks[slot] and stacks[slot].name == remaining.name then
          remaining = world.containerPutItemsAt(entity.id(), remaining, slot - 1) or {}
          if not remaining.count or remaining.count <= 0 then break end
        end
      end
      
      if remaining.count and remaining.count > 0 then
        -- loop through output slots and attempt to place
        for _,slot in pairs(slotConfig.output) do
          remaining = world.containerPutItemsAt(entity.id(), remaining, slot - 1) or {}
          if not remaining.count or remaining.count <= 0 then break end
        end
      end
      
      -- keep trying if container full
      if remaining.count and remaining.count > 0 then remainingOutput[#remainingOutput+1] = remaining end
    end
    
    if #remainingOutput > 0 then
      smelting.results = remainingOutput
    else
      smelting.item = nullItem
      smelting.results = {}
      
      -- take item from input slots that fits a recipe
      local containerItems = world.containerItems(entity.id())
      for _,slot in pairs(slotConfig.input) do
        if containerItems[slot] then
          local item = containerItems[slot]
          
          recipe = recipes[item.name]
          if recipe then
            recipe.count = recipe.count or 1 -- set default if missing
            
            if item.count >= recipe.count then
              -- match! take item
              smelting.item = world.containerTakeNumItemsAt(entity.id(), slot-1, recipe.count)
              smelting.remaining = (recipe.time or smelterConfig.ticksPerItem) / rateMult
              smelting.smeltTime = smelting.remaining
              
              -- determine results
              local results = {}
              smelting.results = results
              if recipe.result then
                local res = recipe.result
                if res.name then res = { res } end -- arrayize if single entry
                for _,r in pairs(res) do
                  if rng:randf() < (r.chance or 1) then -- chance passed or no chance specified
                    results[#results+1] = { name = r.name, count = r.count or 1, parameters = r.parameters or {} }
                  end
                end
              end
              
              script.setUpdateDelta(1) -- resume full tickrate operation
              break -- done here
            end
          end
        end
      end
    end
  end
      
  -- and handle animation states
  if smelting.remaining > 0 then
    object.setAnimationParameter("lit", 1)
  else
    object.setAnimationParameter("lit", 0)
  end
end

function uiSyncRequest(msg, isLocal, ...)
  return {
    batteryStats = { energy = battery.state.energy, capacity = battery.capacity },
    smelting = smelting
  }
end

-- drop currently smelting items on break
function die()
  if smelting and smelting.item and smelting.item.count >= 0 then
    world.spawnItem(smelting.item, world.entityPosition(entity.id()))
  end
end
