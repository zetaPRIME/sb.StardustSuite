--
require "/lib/stardust/itemutil.lua"

local function normalizeItem(itm)
  itm.parameters = itm.parameters or { }
  itm.count = itm.count or 1
  itm.name = itm.name or itm.item
  itm.item = nil
end

function init()
  local recipeData = root.assetJson(metagui.inputData.recipes)
  
  metagui.setTitle(recipeData.title or "Crafting")
  
  local funcFalse = function() return false end
  
  for sid, section in pairs(recipeData.sections) do
    sb.logInfo("section " .. sid)
    local subList = recipeList:addChild { type = "layout", mode = "vertical", spacing = 1, expand = true }
    for rid, recipe in pairs(section.recipes) do
      sb.logInfo("processing recipe \"%s\" in section \"%s\"", rid, sid)
      recipe.id = rid
      normalizeItem(recipe.output)
      local listItem = subList:addChild { type = "listItem", size = {200, 42}, children = { { mode = "vertical", scissoring = false } } }
      listItem.expandMode = {2, 0}
      local topRow = listItem:addChild { type = "layout", mode = "horizontal", align = 0.5 }
      topRow:addChild { type = "itemSlot", item = recipe.output }.isMouseInteractable = funcFalse
      topRow:addChild { type = "label", text = itemutil.property(recipe.output, "shortdescription") }
      local bottomRow = listItem:addChild { type = "layout", mode = "horizontal", align = 0, scissoring = false }
      for _, itm in pairs(recipe.input) do
        normalizeItem(itm)
        bottomRow:addChild { type = "itemSlot", item = itm }.isMouseInteractable = funcFalse
      end
    end
  end
  
  recipeList:queueGeometryUpdate()
end
