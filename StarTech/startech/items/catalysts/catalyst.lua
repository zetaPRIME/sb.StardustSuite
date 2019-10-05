require "/scripts/augments/item.lua"

function apply(input)
  --for k, v in pairs(_ENV) do sb.logInfo(string.format("%s \"%s\"", type(v), k)) end
  
  local data = config.getParameter("catalystData") or { }
  local output = Item.new(input)
  if not output:instanceValue("acceptsUpgradeCatalyst") then return nil end -- only on compatible items (pulse weapons etc.)
  
  local consume = 1
  local ilevel = output:instanceValue("level") or 1
  if data.level then
    if ilevel >= data.level then consume = 0 -- no non-upgrades
    else output:setInstanceValue("level", data.level) end
  end
  
  local odata = output:instanceValue("catalystData") or { }
  if ilevel > (data.level or 1) then -- preserve name and level if already on higher tier, while taking other attributes
    data.name = odata.name or data.name
    data.level = odata.level or data.level
  end
  output:setInstanceValue("catalystData", data)
  output:setInstanceValue("_catalystUpdated", true)
  
  return output:descriptor(), consume
end
