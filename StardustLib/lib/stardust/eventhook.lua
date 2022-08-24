-- eventHook: cross-context event subscription and propagation

local ck = { } -- context key
local keystr = "stardustlib:eventHooks"

local hooks = getmetatable''[keystr]
if not hooks then hooks = { } getmetatable''[keystr] = hooks end

eventHook = { }

local isInit
function eventHook.init()
  if isInit return end
  
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

function eventHook.call(id, ...)
  local h = hooks[id]
  if not h then return end
  for k,v in pairs(h) do pcall(v, ...) end
end
