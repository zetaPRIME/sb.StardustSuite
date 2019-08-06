-- Quickbar conditions module, separated for reuse

conditions = conditions or { }
local function nullfunc() end
function condition(id, ...) return (conditions[id] or nullfunc)(...) end

----------------
-- conditions --
----------------

function conditions.any(...)
  for _, c in pairs{...} do if condition(table.unpack(c)) then return true end end
  return false
end
function conditions.all(...)
  for _, c in pairs{...} do if not condition(table.unpack(c)) then return false end end
  return true
end
conditions["not"] = function(...) return not condition(...) end

function conditions.admin() return player.isAdmin() end
function conditions.statPositive(stat) return status.statPositive(stat) end
function conditions.statNegative(stat) return not status.statPositive(stat) end
function conditions.species(species) return player.species() == species end
function conditions.ownShip() return player.worldId() == player.ownShipWorldId() end
function conditions.hasCompletedQuest(questId) return player.hasCompletedQuest(questId) end

function conditions.configExists(key) return root.assetJson(key) ~= nil end
