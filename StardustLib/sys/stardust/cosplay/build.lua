-- cosplay system armor builder

function build(directory, config, parameters, level, seed)
  if parameters.frames then -- armor ignores parameters; need to modify effective config
    require "/scripts/util.lua"
    config = util.mergeTable({ }, config) -- copy table, otherwise it'll just get reasserted
    
    local frames = parameters.frames
    if type(config.maleFrames or config.femaleFrames) == "table" then
      local blank = "/sys/stardust/cosplay/blank.png"
      if type(frames) == "string" then
        frames = { body = frames }
      end
      frames.body = frames.body or blank
      frames.frontSleeve = frames.frontSleeve or blank
      frames.backSleeve = frames.backSleeve or blank
    end
    
    config.maleFrames = frames
    config.femaleFrames = frames
  end
  
  return config, parameters
end
