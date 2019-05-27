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
        
        local minMods = 2
        local maxMods = 5
        local numMods = math.floor(minMods + (rng.float(0, 1)^2) * (maxMods - minMods - 0.0001))
        local mods = { } parameters.modifiers = mods
        local block = { }
        for i = 1, numMods do
          local m for i = 1, 100 do -- limit retries
            m = gen.modList[rng.int(1, #gen.modList)]
            local mt = string.gsub(m.name, "%.[^%.]*$", "")
            --sb.logInfo("mod class "..mt)
            if (m.minLevel or -1337) > level then m = nil end -- reroll
            if block[mt] then m = nil end
            if m then
              block[mt] = true
            break end
          end
          table.insert(mods, { m.name, rng.float(0.0, 1.0) })
          --sb.logInfo("added mod "..m.name)
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
      
      -- random name generation!
      if not parameters.shortdescription then
        require "/lib/stardust/rng.lua"
        local rng = makeRNG(seed, "name")
        parameters.shortdescription = string.format("%s %s",
          gen.nameGen.first[rng.int(1, #gen.nameGen.first)],
          gen.nameGen.second[rng.int(1, #gen.nameGen.second)]
        )
      end
      
      -- fancy icon
      if not parameters.inventoryIcon then
        require "/lib/stardust/color.lua"
        require "/lib/stardust/rng.lua"
        local rng = makeRNG(seed, "icon")
        
        local hue = 3.0 + rng.float(0.0, 1.0)
        local hRange = 0.44
        local hAdd = rng.float(-hRange, hRange)
        local sat1 = rng.float(0.0, 1.0)^0.25
        local sat2 = rng.float(0.0, 1.0)^0.25
        local lum1 = rng.float(0.9, 1.0)
        local lum2 = rng.float(0.125, 0.275)
        local lumBias = rng.float(1.0, 1.5)
        if rng.int(0, 1) == 0 then lumBias = 1 / lumBias end
        
        local replace = {"fefffe", "d8d2ff", "b79bff", "8e71da", "6e58a9"}
        local pal = { }
        
        local n = #replace for i = 1, n do
          local fade = (i-1)/(n-1)
          table.insert(pal, color.fromHsl { (hue + hAdd*fade)%1.0, util.lerp(fade, sat1, sat2), util.lerp(fade^lumBias, lum1, lum2) })
        end
        
        parameters.inventoryIcon = string.format("type%d.png%s", rng.int(1, gen.iconVariants), color.replaceDirective(replace, pal))
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
