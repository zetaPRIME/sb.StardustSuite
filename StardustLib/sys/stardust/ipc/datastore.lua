-- simple global session data storage

function build(directory, config, parameters, level, seed)
  local ds = getmetatable ''["stardustlib:gdata"]
  if not ds then ds = { } getmetatable ''["stardustlib:gdata"] = ds end
  
  if type(parameters.dataRequest) == "table" then
    parameters.dataReturn = { }
    for k in pairs(parameters.dataRequest) do parameters.dataReturn[k] = ds[k] end
    parameters.dataRequest = nil
  end
  
  if type(parameters.dataInsert) == "table" then
    for k, v in pairs(parameters.dataInsert) do ds[k] = v end
    parameters.dataInsert = nil
  end
  
  return config, parameters
end
