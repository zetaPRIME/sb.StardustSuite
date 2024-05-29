-- build script wrapper for item augments

local ac -- augment config

config = { }
function config.getParameter(key, def)
  local r = ac.parameters[key]
  if r ~= nil then return r end
  r = ac.config[key]
  if r ~= nil then return r end
  sb.logInfo("Augment requests unconfigured key: " .. key)
  return def
end

function build(directory, conf, parameters, level, seed)
  sb.logInfo("build script")
  build = nil
  
  local aug = parameters.augment
  local target = parameters.target
  
  ac = root.itemConfig(aug)
  local sc = config.getParameter("scripts", { })
  for k,v in pairs(sc) do
    sb.logInfo("augment script: " .. v)
    require(v)
  end
  
  parameters = { result = apply(target) }
  
  return conf, parameters
end
