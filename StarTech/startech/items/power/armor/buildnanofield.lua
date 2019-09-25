-- multibuild script

local buildList = {
  "/sys/stardust/builders/powered.lua",
  "/startech/items/active/weapons/buildpulseweapon.lua",
}

local function nbuild(directory, config, parameters, level, seed) return config, parameters end

function build(directory, config, parameters, level, seed)
  for _, builder in pairs(buildList) do
    build = nf
    require(builder)
    config, parameters = build(directory, config, parameters, level, seed)
  end
  return config, parameters
end
