local mg = metagui
local m = settings.module { weight = -10000 }

local function default(v, d)
  if v == nil then return d end
  return v
end


do
  local p = m:page { title = "UI Themes", icon = "themes.png",
    contents = {
      { type = "panel", style = "concave", expandMode = {1, 2}, children = {
        { type = "scrollArea", id = "themeList", children = { { spacing = 1 } } }
      } }
    }
  }
  
  local tp = m:page { title = "Theme Settings", icon = "themesettings.png",
    contents = {
      { type = "layout", id = "stack", mode = "stack", expandMode = {2, 2} }
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
    local theme = themes[w.theme]
    if not theme then -- default, no settings
      tp.tab:setVisible(false)
      return
    end
    tp.tab.titleWidget:setText(theme.name)
    tp.tab:setVisible(not not theme.hasSettingsPanel)
  end
  
  local function addThemeEntry(themeId)
    local theme = themes[themeId] or defaultInfo
    local li = p.themeList:addChild {
      type = "listItem", size = {128, 32}, children = { -- set to 48 when preview pics are in
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
    if not themes[def] then def = next(themes) end
    defaultInfo.name = string.format(defaultInfo.name, themes[def].name)
    
    local themeOrder = { }
    for _, theme in pairs(themes) do table.insert(themeOrder, theme) end
    table.sort(themeOrder, function(a, b) return (b.sortWeight or 0) > (a.sortWeight or 0) end)
    
    addThemeEntry()
    for _, theme in pairs(themeOrder) do
      addThemeEntry(theme.id)
    end
  end
  
  -- -- --
  
  function _ENV.themeSettings()
    return themes[mg.settings.theme].settingsModule
  end
  
  local themeSettings = { }
  themeSettings.__index = themeSettings
  
  function themeSettings:init() end
  function themeSettings:save() end
  
  function tp:init()
    --
  end
  
  function tp:onSwitch()
    local theme = themes[mg.settings.theme]
    if not theme.settingsModule then
      -- set up settings table
      if not mg.settings.themeSettings then mg.settings.themeSettings = { } end
      local tst = util.mergeTable({ }, theme.defaultSettings or { })
      util.mergeTable(tst, mg.settings.themeSettings[theme.id] or { })
      mg.settings.themeSettings[theme.id] = tst -- install
      
      -- and the module itself
      local ts = setmetatable({ theme = theme, settings = tst }, themeSettings)
      theme.settingsModule = ts
      
      mg.cfg.assetPath = theme.path
      mg.widgetContext = ts
      require(theme.path .. "settings.lua")
      ts.page = mg.createImplicitLayout(ts.contents or ts.layout, tp.stack, { mode = "vertical", expandMode = {2, 2} })
      ts:init()
    end
    
    for _, pg in pairs(tp.stack.children) do
      pg:setVisible(pg == theme.settingsModule.page)
    end
  end
  
  function tp:save()
    for _, t in pairs(themes) do
      if t.settingsModule then t.settingsModule:save() end
    end
  end
  
  
end
do
  local p = m:page { title = "General", icon = "settings.icon.png",
    contents = {
      { { type = "checkBox", id = "quickbarAutoDismiss", checked = default(mg.settings.quickbarAutoDismiss, true) }, { type = "label", text = "Dismiss Quickbar on selection" } },
      8, -- spacer
      { -- sidebars
        { -- left
          { type = "panel", style = "convex", children = {
            { type = "label", text = "Scrolling mode", inline = true },
              { { type = "checkBox", id = "scrollWF", radioGroup = "scrollMode", value = {true, true} }, { type = "label", text = "Wheel & Fling" } },
              { { type = "checkBox", id = "scrollW", radioGroup = "scrollMode", value = {true, false} }, { type = "label", text = "Wheel only" } },
              { { type = "checkBox", id = "scrollF", radioGroup = "scrollMode", value = {false, true} }, { type = "label", text = "Fling only" } },
          } },
        },
        {"spacer"}, -- right (blank for now)
      }
    }
  }
  
  function p:init()
    -- load scroll mode
    local sm = mg.settings.scrollMode or {true, true}
    if sm[1] and not sm[2] then p.scrollW:setChecked(true)
    elseif sm[2] and not sm[1] then p.scrollF:setChecked(true)
    else p.scrollWF:setChecked(true) end -- done like this so "both" is selected if neither flag is set
  end
  
  function p:save()
    mg.settings.quickbarAutoDismiss = p.quickbarAutoDismiss.checked
    mg.settings.scrollMode = p.scrollWF:getGroupValue()
  end
  
end
--local aaa = m:page { title = "Another tab's testing" }
