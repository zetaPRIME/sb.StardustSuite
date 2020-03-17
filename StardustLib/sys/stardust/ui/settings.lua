-- settings UI... just theme selection for now

local defaultInfo = {
  --defaultAccentColor = "accent",
  name = "Default (%s)",
  description = "No preference selected",
}

local themes = { }
function init()
  local tl = root.assetJson("/metagui/registry.json:themes")
  for k, p in pairs(tl) do
    themes[k] = root.assetJson(p .. "theme.json")
    themes[k].path = p
  end
  
  local def = root.assetJson("/panes.config").metaGUI.defaultTheme
  if not themes[def] then for k in pairs(themes) do def = k break end end
  defaultInfo.name = string.format(defaultInfo.name, themes[def].name)
  
  addThemeEntry()
  for k in pairs(themes) do
    addThemeEntry(k)
  end
end

function addThemeEntry(themeId)
  local theme = themes[themeId] or defaultInfo
  local li = themeList:addChild {
    type = "listItem", children = {
      { mode = "horizontal" },
      {
        { type = "label", color = theme.defaultAccentColor, text = theme.name },
        { type = "label", --[[color = "bfbfbf",]] text = theme.description }
      }
    }
  }
  li.theme = themeId
  li.onSelected = themeSelected
  if themeId == metagui.settings.theme then li:select() end
end

function themeSelected(w)
  metagui.settings.theme = w.theme
end

function apply:onClick()
  player.setProperty("metaGUISettings", metagui.settings)
end
