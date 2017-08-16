-- Require within init()

if storage then -- configurable entity
  storage.config = storage.config or {}
  
  local function getCfg(msg, isLocal)
    return storage.config
  end
  local function setCfg(msg, isLocal, cfg)
    storage.config = cfg or {}
    if onSetConfig then onSetConfig() end
    return storage.config
  end
  
  message.setHandler("getConfig", getCfg)
  message.setHandler("setConfig", setCfg)
else -- probably an interface
  require "/lib/stardust/sync.lua"
  
  -- hmm.
end
