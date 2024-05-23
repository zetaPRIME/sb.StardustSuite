-- eventHook: cross-script event subscription and propagation

require "/lib/stardust/sharedtable.lua"

local ck = { } -- context key
local hooks = sharedTable "stardustlib:eventHook"

eventHook = { }

local isInit
function eventHook.init()
  if isInit then return end
  
  -- set up uninit hook
  local _uninit = uninit
  function uninit(...)
    eventHook.uninit()
    if _uninit then _uninit(...) end
  end
  
  isInit = true
end

function eventHook.uninit()
  for k,v in pairs(hooks) do
    v[ck] = nil
  end
end

function eventHook.subscribe(id, func)
  eventHook.init() -- automation
  local h = hooks[id]
  if not h then
    h = setmetatable({ }, { __mode = 'k' })
    hooks[id] = h
  end
  
  h[ck] = func
end

function eventHook.subscribeClient(id, func)
  if world and not world.setPlayerStart then eventHook.subscribe(id, func) end
end

function eventHook.subscribeServer(id, func)
  if world and world.setPlayerStart then eventHook.subscribe(id, func) end
end

function eventHook.unsubscribe(id)
  local h = hooks[id]
  if h then h[ck] = nil end
end

function eventHook.call(id, ...)
  local h = hooks[id]
  if not h then return end
  for k,v in pairs(h) do pcall(v, ...) end
end
