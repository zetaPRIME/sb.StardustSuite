--

local src = metagui.cfg.inputData.src

local uiColors = {
  {"?hueshift=-110?saturation=40?brightness=10", "d10004", "Red"}, -- red
  {"?hueshift=-80?saturation=80?brightness=35", "e49d00", "Orange"}, -- orange
  {"?hueshift=-55?saturation=76?brightness=40", "e6e000", "Yellow"}, -- yellow
  --[""] == "59c834", -- green
  {"?hueshift=45?saturation=50?brightness=10", "00d197", "Mint"}, -- mint
  {"?hueshift=65?saturation=65?brightness=20", "00d9d1", "Cyan"}, -- cyan
  {"?hueshift=88?saturation=50?brightness=14","34c6e2", "Blue"}, -- blue
  {"?hueshift=100?saturation=50?brightness=0", "0081c8", "Dark Blue"}, -- darkblue
  {"?hueshift=155?saturation=20?brightness=15", "7900d5", "Purple"}, -- purple
  {"?hueshift=180?saturation=40?brightness=15", "c100d5", "Pink"}, -- pink
}

local guiColor = world.getObjectParameter(src, "guiColor")

local cp = radColor.parent.parent
for k,v in pairs(uiColors) do
  metagui.createImplicitLayout({
    { type = "checkBox", radioGroup = "color", value = v[1], checked = (v[1] == guiColor) },
    { type = "label", text = "^#" .. v[2] .. ";" .. v[3] }
  }, cp)
end
if not guiColor then radColor:setChecked(true) end

txtName:setText(world.getObjectParameter(src, "shortdescription"))

local keep = world.getObjectParameter(src, "keepContent")
if keep == nil then keep = true end
keepItems:setChecked(keep)

function cancel:onClick()
  pane.dismiss()
end

local function waitPromise(p)
  while not p:finished() do coroutine.yield() end
end

function apply:onClick()
  -- send data
  world.sendEntityMessage(src, "renameContainer", txtName.text)
  world.sendEntityMessage(src, "keepContent", keepItems.checked)
  world.sendEntityMessage(src, "interfaceColors", radColor:getGroupValue())
  -- signal to show save message
  waitPromise(world.sendEntityMessage(src, "saveOptions"))
  
  waitPromise(world.sendEntityMessage(src, "")) -- wait for one more sync, then...
  --player.interact("OpenContainer", nil, src) -- reopen chest UI
  pane.dismiss() -- close (which reopens the chest UI)
end

function update()
  if metagui.ipc.openContainerProxy then pane.dismiss() end
end

metagui.registerUninit(function()
  if metagui.ipc.openContainerProxy then -- guard against weird container behavior
    player.interact("OpenContainer", nil, metagui.ipc.openContainerProxy) -- force reopen specified container
  else
    player.interact("OpenContainer", nil, src) -- reopen chest UI
  end
end)
