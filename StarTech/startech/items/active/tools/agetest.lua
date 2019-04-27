--require("/items/buildscripts/buildunrandweapon.lua")

function ageItem(baseItem, aging)
  sb.logInfo("age called on '" .. baseItem.name .. "': " .. aging)
  return baseItem
end

function build(directory, config, parameters, level, seed)
  sb.logInfo("build script called!")
  return config, parameters
end
