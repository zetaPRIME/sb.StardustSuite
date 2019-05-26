local gen
function build(directory, config, parameters, level, seed)
  if config.randomize then
    if not parameters.jewelGrants or parameters.generatorVersion ~= root.assetJson("/aetheri/jewels/generator.config:generatorVersion") then
      parameters.jewelGrants = nil
      
      require "/scripts/util.lua"
      if not gen then gen = root.assetJson("/aetheri/jewels/generator.config") end
      
      level = level or parameters.level or config.level or 1
      seed = seed or parameters.seed or config.seed or sb.staticRandomI32(util.seedTime(), "LOST LOGIA: JEWEL SEED")
      parameters.level = level
      parameters.seed = seed
      
      parameters.generatorVersion = gen.generatorVersion
      
      -- TODO: randomly generate jewel
      --parameters.shortdescription = "level:" .. level .. ",seed:" .. seed
      
      if not parameters.modifiers then
        require "/lib/stardust/rng.lua"
        local rng = makeRNG(seed, "modifiers")
        
        -- assemble relevant modifier data
        gen.modList = { } for k, m in pairs(gen.modifiers) do m.name = k table.insert(gen.modList, m) end
        
        local numMods = rng.int(1, 5)
        local mods = { } parameters.modifiers = mods
        for i = 1, numMods do
          local m while not m do
            m = gen.modList[rng.int(1, #gen.modList)]
            if (m.minLevel or -1337) > level then m = nil end -- reroll
          end
          table.insert(mods, { m.name, rng.float(0.0, 1.0) })
          sb.logInfo("added mod "..m.name)
        end
      end
      
      if not parameters.jewelGrants then
        local jg = { } parameters.jewelGrants = jg
        for _, m in pairs(parameters.modifiers) do
          local mod = gen.modifiers[m[1]]
          if mod then
            local g = copy(mod.grants)
            if type(g[3]) == "table" then
              local step = mod.step or gen.defaultStep[g[1]] or 1
              g[3] = math.floor(0.5 + util.lerp(m[2], g[3][1], g[3][2]) / step) * step
            end
            table.insert(jg, g)
          end
        end
      end
      
      if not parameters.shortdescription then
        require "/lib/stardust/rng.lua"
        local rng = makeRNG(seed, "name")
        parameters.shortdescription = string.format("%s %s",
          gen.nameGen.first[rng.int(1, #gen.nameGen.first)],
          gen.nameGen.second[rng.int(1, #gen.nameGen.second)]
        )
      end
      
    end
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
