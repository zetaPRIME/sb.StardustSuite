-- item disappears when dropped or placed in a container
-- ... not sure if this can actually be done.

function build(directory, config, parameters, level, seed)
  if not getmetatable ''.clientSide then
    --return { }, { }
  end
  
  return config, parameters
end
