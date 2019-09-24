require "/scripts/augments/item.lua"

function apply(input)
  --for k, v in pairs(_ENV) do sb.logInfo(string.format("%s \"%s\"", type(v), k)) end
  
  local data = config.getParameter("catalystData") or { }
  local output = Item.new(input)
  if not output:instanceValue("acceptsUpgradeCatalyst") then return nil end -- only on compatible items (pulse weapons etc.)
  
  if data.level then
    if (output:instanceValue("level") or 1) >= data.level then return nil end -- no non-upgrades
    output:setInstanceValue("level", data.level)
  end
  
  output:setInstanceValue("catalystData", data)
  
  return output:descriptor(), 1
end
