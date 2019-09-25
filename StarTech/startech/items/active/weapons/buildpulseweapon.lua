-- stuff

function build(directory, config, parameters, level, seed)
  --
  
  level = parameters.level or config.level or level or 1
  parameters.level = level
  
  local lvLabel = string.format("^gray;Level: ^white;%i^reset;", math.floor(0.5 + level))
  if parameters.catalystData and parameters.catalystData.name then
    lvLabel = string.format("%s ^lightgray;(%s)^reset;", lvLabel, parameters.catalystData.name)
  else
    lvLabel = string.format("%s ^darkgray;(no catalyst)^reset;", lvLabel)
  end
  
  parameters.tooltipFields = parameters.tooltipFields or { }
  parameters.tooltipFields.bottomLabel = lvLabel
  
  return config, parameters
end
