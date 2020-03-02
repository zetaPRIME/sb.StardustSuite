-- converts an item entirely to another

function build(directory, config, parameters, level, seed)
  if not config.convertsTo then
    sb.logWarn("Item \"" .. (config.itemName or config.objectName) .. "\" has no conversion specified")
    return config, parameters
  end
  
  local cfg = { }
  for k, v in pairs(config) do cfg[k] = v end
  cfg.convertsTo = nil cfg.builder = nil
  cfg.itemName = config.convertsTo
  cfg.objectName = config.convertsTo
  return cfg, parameters
end
