--

local appearance
local loaded
function init()
  appearance = status.statusProperty("aetheri:appearance")
  if not appearance then pane.dismiss() return nil end
  
  widget.setSliderValue("hue", appearance.coreHsl[1] * 1000)
  widget.setSliderValue("sat", appearance.coreHsl[2] * 1000)
  widget.setSliderValue("lumBright", appearance.coreHsl[3] * 1000)
  widget.setSliderValue("lumDark", appearance.coreHsl[4] * 1000)
  loaded = true
end

function update()
  widget.setText("ap", string.format("%dAP", math.floor(status.statusProperty("aetheri:AP", 0))))
end

function changed()
  if not loaded then return nil end -- don't try to fudge this while still loading in the existing values!
  appearance.coreHsl = {
    widget.getSliderValue("hue") / 1000,
    widget.getSliderValue("sat") / 1000,
    widget.getSliderValue("lumBright") / 1000,
    widget.getSliderValue("lumDark") / 1000
  }
  status.setStatusProperty("aetheri:appearance", appearance)
  world.sendEntityMessage(player.id(), "aetheri:refreshAppearance")
end
