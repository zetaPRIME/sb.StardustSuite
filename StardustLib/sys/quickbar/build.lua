-- metaGUI quickbar builder

require "/sys/quickbar/conditions.lua"

cfg = {
  style = "panel",
  uniqueBy = "path", uniqueMode = "toggle",
  itemDefs = { },
  scripts = { "quickbar.lua" },
}

local colorSub = { -- color tag substitutions
  ["^essential;"] = "^#ffb133;",
  ["^admin;"] = "^#bf7fff;",
}

local function legacyAction(i)
  if i.pane then return { "pane", i.pane } end
  if i.scriptAction then
    sb.logInfo(string.format("Quickbar item \"%s\": scriptAction is deprecated, please use new entry format", i.label))
    return { "_legacy_module", i.scriptAction }
  end
  return { "null" }
end

do -- build the actual list
  local c = root.assetJson("/quickbar/icons.json")
  local items = { }
  
  for _, i in pairs(c.items) do -- dump in normal items
    if not i.condition or condition(table.unpack(i.condition)) then
      table.insert(items, i)
    end
  end
    
  -- and then translate legacy entries
  for _, i in pairs(c.priority) do
    table.insert(items, {
      label = "^essential;" .. i.label,
      icon = i.icon,
      weight = -1100,
      action = legacyAction(i)
    })
  end
  if player.isAdmin() then
    for _, i in pairs(c.admin) do
      table.insert(items, {
        label = "^admin;" .. i.label,
        icon = i.icon,
        weight = -1000,
        action = legacyAction(i),
        condition = { "admin" }
      })
    end
  end
  for _, i in pairs(c.normal) do
    table.insert(items, {
      label = i.label,
      icon = i.icon,
      action = legacyAction(i)
    })
  end
  
  -- sort by weight then alphabetically, ignoring caps and tags (and doing tag substitutions while we're here)
  for _, i in pairs(items) do
    i._sort = string.lower(string.gsub(i.label, "(%b^;)", ""))
    i.label = string.gsub(i.label, "(%b^;)", colorSub)
    i.weight = i.weight or 0
    --sb.logInfo("label: "..i.label.."\nsort: "..i._sort)
  end
  table.sort(items, function(a, b) return a.weight < b.weight or (a.weight == b.weight and a._sort < b._sort) end)
  
  -- and add items to pane list
  local width = 128
  local height = 0
  local itmHeight = 20
  local oItems = { { spacing = 0 } }
  for idx = 1, #items do
    local i = items[idx]
    
    height = height + itmHeight
    table.insert(oItems, {
      type = "menuItem", size = {width, itmHeight}, data = i, padding = 0,
      children = { { scissoring = false },
        { type = "label", align = "right", text = i.label },
        { type = "image", size = {itmHeight, itmHeight}, file = i.icon or "/items/currency/essence.png" },
      }
    })
  end
  
  height = math.min(height, 290) -- limit height to scale point
  cfg.size = {width, height}
  cfg.children = {
    { type = "scrollArea", children = oItems, id = "itemField" },
  }
  cfg.anchor = {
    "topRight",
    {-24, math.max(47, 114 - height/2)} -- expand evenly from center of button until reaching top of crafting button
  }
  
  -- warn about excess bees
  if (xsb or player.addChatBubble) and (os.time() - (60*60*3) >= player.getProperty("__excess_bees_warned", 0)) then
    player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = "stardustlib:excessbees" })
    cfg = nil -- no quickbar
  end
  
end
