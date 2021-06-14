function update(...)
  --[[sb.logInfo("updating")
  for k, v in pairs {...} do
    sb.logInfo(string.format("key \"%s\" of type %s", k, type(v)))
  end]]
end

function init()
  --[[for k,v in pairs(mcontroller) do
    sb.logInfo("mcontroller." .. k)
  end]]
end

--setmetatable(_ENV, {__index = function(_, n) sb.logInfo("unknown func " .. n) end})
