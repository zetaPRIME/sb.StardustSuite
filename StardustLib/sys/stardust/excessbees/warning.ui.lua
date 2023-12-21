--

local okClicked = false

function ok.onClick()
  okClicked = true
  pane.dismiss()
end

function uninit()
  if not okClicked then -- require confirmation before allowing quickbar again
    player.setProperty("__excess_bees_warned", nil)
  else
    player.setProperty("__excess_bees_warned", os.time())
  end
end
