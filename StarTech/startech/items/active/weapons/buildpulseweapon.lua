-- stuff

function build(directory, config, parameters, level, seed)
  --
  
  level = parameters.level or config.level or level or 1
  parameters.level = level
  
  parameters.tooltipFields = {
    bottomLabel = string.format("^gray;Level: ^white;%i", level)
  }
  
  return config, parameters
end
