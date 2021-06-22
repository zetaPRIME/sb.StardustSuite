local hook = { }
_ENV["$$cphook"] = hook
function hook.get() return hook end -- easy pickup

hook.active = { }

local function nullFunc() end

local _cc = _ENV.containerCallback or nullFunc
function containerCallback()
  _cc()
  for cp in pairs(hook.active) do cp:sendUpdate() end
end

local _uninit = _ENV.uninit or nullFunc
function _ENV.uninit()
  for cp in pairs(hook.active) do cp:disconnect() end
  _uninit()
end
