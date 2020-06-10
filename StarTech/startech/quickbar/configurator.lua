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
  local paneDef = itemutil.property(itm, "/startech:configuratorPane")
  local uiDef = itemutil.property(itm, "/startech:configuratorUI")
  if uiDef then
    player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = uiDef })
  elseif paneDef then
    if type(paneDef) == "string" then
      local dir = root.itemConfig(itm.name).directory
      player.interact("ScriptPane", util.absolutePath(dir, paneDef))
    elseif type(paneDef) == "table" then
      player.interact(table.unpack(paneDef))
    end
  else
    pane.playSound("/sfx/interface/clickon_error.ogg")
    playerext.message("Must be holding configurable item in cursor.")
    return nil
  end
end
