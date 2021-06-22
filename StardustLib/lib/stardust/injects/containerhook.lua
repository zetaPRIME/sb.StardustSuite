local hook = { }
_ENV["$$cthook"] = hook
function hook.get() return hook end -- easy pickup

hook.active = { }

local function nullFunc() end

local _cc = _ENV.containerCallback or nullFunc
function containerCallback()
  _cc()
  for ct in pairs(hook.active) do ct:onUpdate() end
end

local _uninit = _ENV.uninit or nullFunc
function _ENV.uninit()
  for ct in pairs(hook.active) do ct:disconnect() end
  _uninit()
end
