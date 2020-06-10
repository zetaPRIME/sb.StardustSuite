-- configurator query window
require "/lib/stardust/itemutil.lua"

metagui.startEvent(function()
  for t = 0,60*15 do
    local itm = player.swapSlotItem()
    if itm then
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
        lbl:setText("Item has no configuration.")
        for t = 0,60*3 do
          coroutine.yield()
        end
        return pane.dismiss()
      end
      return pane.dismiss()
    end
    coroutine.yield()
  end
  pane.dismiss()
end)
