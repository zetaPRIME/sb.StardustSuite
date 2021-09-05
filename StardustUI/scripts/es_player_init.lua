-- this file is here to disable the "idiot check" and associated radio message from Enhanced Storage
-- our modifications trip it, but we are very much compatible

local _init = init
function init(...)
  if _init then _init(...) end
  -- still need to set this though
  player.setUniverseFlag "outpost_enhancedstorage"
end
