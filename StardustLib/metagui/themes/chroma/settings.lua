require "/lib/stardust/color.lua"

local ts = themeSettings()
ts.layout = {
  {
    { type = "checkBox", id = "randomColor", radioGroup = "randomColor" },
    { type = "label", text = "Use random color if pane doesn't specify" },
  },
  {
    { type = "checkBox", checked = true, radioGroup = "randomColor" },
    { type = "label", text = "Use custom color scheme:" },
  },
  { type = "panel", expandMode = {2, 0}, children = { { mode = "horizontal" },
    { type = "label", inline = true, text = "Base" }, { type = "textBox", id = "baseColor", caption = ts.theme.defaultAccentColor },
    { type = "label", inline = true, text = "Trim" }, { type = "textBox", id = "trimColor" },
    { type = "label", inline = true, text = "Accent" }, { type = "textBox", id = "accentColor" },
  } },
  
  {
    { type = "checkBox", id = "overrideColors" },
    { type = "label", text = "Override pane-specified colors" },
  },
  
}

local function onColorChanged(self)
  local c = color.validateHex(self.text)
  self.color = c and color.hexWithAlpha(c, 1, true) or nil
end

function ts:init()
  -- display color preview while typing
  ts.baseColor.onTextChanged = onColorChanged
  ts.trimColor.onTextChanged = onColorChanged
  ts.accentColor.onTextChanged = onColorChanged
  
  -- allow navigating between color fields via enter/esc
  function ts.baseColor:onEnter() ts.trimColor:focus() end
  function ts.trimColor:onEnter() ts.accentColor:focus() end
  function ts.accentColor:onEscape() ts.trimColor:focus() end
  function ts.trimColor:onEscape() ts.baseColor:focus() end
  
  -- and load in settings
  ts.randomColor:setChecked(ts.settings.randomColor)
  ts.overrideColors:setChecked(ts.settings.overrideColors)
  
  ts.baseColor:setText(ts.settings.baseColor)
  ts.trimColor:setText(ts.settings.trimColor)
  ts.accentColor:setText(ts.settings.accentColor)
end

function ts:save()
  ts.settings.randomColor = ts.randomColor.checked
  ts.settings.overrideColors = ts.overrideColors.checked
  
  ts.settings.baseColor = color.validateHex(ts.baseColor.text)
  ts.settings.trimColor = color.validateHex(ts.trimColor.text)
  ts.settings.accentColor = color.validateHex(ts.accentColor.text)
end
