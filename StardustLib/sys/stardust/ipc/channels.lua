-- channel-based ipc transaction system

function build(directory, config, parameters, level, seed)
  if not parameters.query then
    return config, { error = "No query specified." }
  end
  
  
  local ipc = getmetatable ''["stardustlib:channelipc"]
  if not ipc then ipc = { } getmetatable ''["stardustlib:channelipc"] = ipc end
  
  local cmd, p = parameters.query[1], { table.unpack(parameters.query, 2) }
  
  if cmd == "" then
    
  else
    return config, { error = string.format("Unknown command \"%s\"", cmd) }
  end
  
  -- eh whatever
  return config, { }
end
