
function build(directory, config, parameters, level, seed)
  if config.randomize and not parameters.jewelGrants then
    -- TODO: randomly generate jewel
  end
  
  local grants = parameters.jewelGrants or config.jewelGrants
  if grants then
    require "/scripts/util.lua"
    require "/aetheri/interface/skilltree/tooltip.lua"
    config = util.mergeTable({ }, config) -- copy table, otherwise it'll just get reasserted
    config.category = "aetheri:skilljewel"
    
    config.description = generateGrantToolTip(grants)
  end
  
  return config, parameters
end
