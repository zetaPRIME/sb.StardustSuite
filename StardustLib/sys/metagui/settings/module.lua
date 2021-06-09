local m = settings.module { weight = -10000 }


do
  local p = m:page { title = "UI Themes",
    contents = {
      { type = "panel", style = "concave", expandMode = {1, 2}, children = {
        { type = "scrollArea", id = "themeList", children = { { spacing = 1 } } }
      } }
    }
  }
  
  local themes = { }
  local defaultInfo = {
    -- defaultAccentColor = "accent",
    name = "Default (%s)",
    description = "No preference selected",
  }
  
  local function themeSelected(w)
    metagui.settings.theme = w.theme
  end
  
  local function addThemeEntry(themeId)
    local theme = themes[themeId] or defaultInfo
    local li = p.themeList:addChild {
      type = "listItem", size = {128, 32+2*2}, children = { -- set to 48 when preview pics are in
        { mode = "horizontal" },
        {
          { type = "label", color = theme.defaultAccentColor, text = theme.name },
          { type = "label", color = "bfbfbf", text = theme.description }
        }
      }
    }
    li.theme = themeId
    li.onSelected = themeSelected
    if themeId == metagui.settings.theme then li:select() end
  end
  
  function p:init()
    for k, p in pairs(registry.themes) do
      themes[k] = root.assetJson(p .. "theme.json")
      themes[k].id = k
      themes[k].path = p
    end
    
    local def = registry.defaultTheme
    if not themes[def] then for k in pairs(themes) do def = k break end end
    defaultInfo.name = string.format(defaultInfo.name, themes[def].name)
    
    local themeOrder = { }
    for _, theme in pairs(themes) do table.insert(themeOrder, theme) end
    table.sort(themeOrder, function(a, b) return (b.sortWeight or 0) > (a.sortWeight or 0) end)
    
    addThemeEntry()
    for _, theme in pairs(themeOrder) do
      addThemeEntry(theme.id)
    end
  end
end
local p2 = m:page { title = "I'm here too." }
