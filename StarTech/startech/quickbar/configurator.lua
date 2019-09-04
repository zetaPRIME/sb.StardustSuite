require "/scripts/util.lua"
require "/lib/stardust/itemutil.lua"
require "/lib/stardust/playerext.lua"

local tierReqs = {
  { name = "ironbar", count = 5 },
  { name = "tungstenbar", count = 5 },
  { name = "titaniumbar", count = 15 },
  { name = "durasteelbar", count = 20 },
  { name = "refinedviolium", count = 20 },
  { name = "solariumstar", count = 20 },
}

do
  local itm = player.swapSlotItem() or { }
  local uiDef = itemutil.property(itm, "/startech:configuratorUi")
  if not uiDef then
    pane.playSound("/sfx/interface/clickon_error.ogg")
    playerext.message("Must be holding configurable item.")
    return nil
  end
  if type(uiDef) == "string" then
    local dir = root.itemConfig(itm.name).directory
    player.interact("ScriptPane", util.absolutePath(dir, uiDef))
  elseif type(uiDef) == "table" then
    player.interact(table.unpack(uiDef))
  end
  
  
end
