-- configurator query window
require "/lib/stardust/itemutil.lua"

local silly = {
  "All your base are belong to us.",
  "Mischief managed!",
  "Running in the nineties...",
  "]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]]",
  "And a step to the right!",
  "Reticulating splines...",
  "Was yea ra chs hymmnos mea...",
  "=(^_^)=",
  "OwO",
}

metagui.startEvent(function()
  pane.playSound "/sfx/interface/stationtransponder_stationpulse.ogg"
  for t = 0,60*5 do
    local itm = player.swapSlotItem()
    if itm then
      local paneDef = itemutil.property(itm, "/startech:configuratorPane")
      local uiDef = itemutil.property(itm, "/startech:configuratorUI")
      if uiDef then
        _ENV.inputcfg = uiDef
        require "/sys/metagui/build.lua"
      elseif paneDef then
        if type(paneDef) == "string" then
          local dir = root.itemConfig(itm.name).directory
          player.interact("ScriptPane", util.absolutePath(dir, paneDef))
        elseif type(paneDef) == "table" then
          player.interact(table.unpack(paneDef))
        end
      else
        pane.playSound "/sfx/interface/clickon_error.ogg"
        lbl:setText("Item is not configurable.")
        for t = 0,60*3 do
          coroutine.yield()
        end
        return pane.dismiss()
      end
      pane.playSound "/sfx/objects/outpostbutton.ogg"
      if math.random(1, 10) < 2 then
        lbl:setText(util.randomChoice(silly))
      else
        lbl:setText("Opening interface...")
      end
      for t = 0,15 do coroutine.yield() end
      return pane.dismiss()
    end
    coroutine.yield()
  end
  pane.dismiss()
end)
