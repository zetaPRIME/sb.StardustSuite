-- stuff

function build(directory, config, parameters, level, seed)
  --sb.logInfo("build script called!")
  
  local capacity = (parameters.batteryStats or {}).capacity or (config.batteryStats or {}).capacity or 0
  local energy = (parameters.batteryStats or {}).energy or 0
  
  if not parameters.tooltipFields then parameters.tooltipFields = {} end
  parameters.tooltipFields.batteryStatsLabel = string.format("%d^gray;/^reset;%d^gray;FP^reset;", math.floor(0.5 + energy), math.floor(0.5 + capacity))
  
  return config, parameters
end
