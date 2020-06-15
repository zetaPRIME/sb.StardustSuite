--
require "/lib/stardust/itemutil.lua"

local currentRecipe

local function normalizeItem(itm)
  --itm.parameters = itm.parameters or { }
  itm.count = itm.count or 1
  itm.name = itm.name or itm.item
  itm.item = nil
end

function init()
  local recipeData = root.assetJson(metagui.inputData.recipes)
  
  metagui.startEvent(function()
    local title = recipeData.title or "Crafting"
    coroutine.yield()
    metagui.setTitle(title)
  end)
  
  local funcFalse = function() return false end
  local function entrySort(a, b) return (a.sortId or a.id) < (b.sortId or b.id) end
  
  local function onRecipeSelected(self)
    recipeList:pushEvent("listItemSelected", self)
    selectRecipe(self.recipe)
  end
  
  
  -- assemble sorted section list
  local sections = { }
  for sid, section in pairs(recipeData.sections) do
    section.id = sid
    table.insert(sections, section)
  end table.sort(sections, entrySort)
  
  for _, section in pairs(sections) do
    local sectionBtn = recipeList:addChild { type = "button", expand = true, caption = section.name or sid }
    local subList = recipeList:addChild { type = "layout", mode = "vertical", spacing = 1, expand = true }
    subList:setVisible(false)
    function sectionBtn:onClick()
      subList:setVisible(not subList.visible)
      -- show scroll indicators
      coroutine.yield() coroutine.yield()
      recipeList:scrollBy {1, 0}
    end
    
    -- assemble sorted recipe list
    local recipes = { }
    for rid, recipe in pairs(section.recipes) do
      recipe.id = rid
      normalizeItem(recipe.output)
      for _, itm in pairs(recipe.input) do normalizeItem(itm) end
      table.insert(recipes, recipe)
    end table.sort(recipes, entrySort)
    
    for _, recipe in pairs(recipes) do
      --if not currentRecipe then currentRecipe = recipe end
      local listItem = subList:addChild { type = "listItem", size = {200, 42}, children = { { mode = "vertical", scissoring = false } } }
      listItem.recipe = recipe
      listItem.onSelected = onRecipeSelected
      
      -- populate info rows
      local topRow = listItem:addChild { type = "layout", mode = "horizontal", align = 0.5, scissoring = false }
      local bottomRow = listItem:addChild { type = "layout", mode = "horizontal", align = 0, scissoring = false }
      topRow:addChild { type = "itemSlot", item = recipe.output }.isMouseInteractable = funcFalse
      topRow:addChild { type = "spacer", size = -1 }
      local lbl = string.format("^shadow;%s", itemutil.property(recipe.output, "shortdescription"))
      if recipe.output.count > 1 then lbl = string.format("%s ^lightgray;(x^reset;^shadow;%d^lightgray;)", lbl, recipe.output.count) end
      local nameLabel = topRow:addChild { type = "label", text = lbl }
      nameLabel:subscribeEvent("updateCraftableCounts", function()
        local col = craftableCount(recipe) < 1 and "7f7f7f"
        if nameLabel.color ~= col then nameLabel.color = col nameLabel:queueRedraw() end
      end)
      nameLabel:pushEvent("updateCraftableCounts")
      for _, itm in pairs(recipe.input) do
        bottomRow:addChild { type = "itemSlot", item = itm }.isMouseInteractable = funcFalse
      end
    end
  end
  
  if currentRecipe then selectRecipe(currentRecipe) end
  
  -- refresh counts periodically
  metagui.startEvent(function()
    while true do
      for i=0,60 do coroutine.yield() end
      metagui.broadcast("updateCraftableCounts")
    end
  end)
end

function hasItem(itm)
  local currency = itemutil.property(itm, "currency")
  if currency then return player.currency(currency) end
  return player.hasCountOfItem(itm, not not itm.parameters)
end

function consumeItem(itm, mult)
  mult = mult or 1
  local currency = itemutil.property(itm, "currency")
  if currency then
    player.consumeCurrency(currency, itm.count * mult)
  else
    player.consumeItem({ name = itm.name, count = itm.count * mult, parameters = itm.parameters }, true, not not itm.parameters)
  end
end

function craftableCount(recipe)
  local cc = math.huge
  for _, itm in pairs(recipe.input) do
    if itm.count > 0 then cc = math.min(cc, math.floor(hasItem(itm) / itm.count)) end
    if cc <= 0 then return 0 end
  end
  return cc
end

function selectRecipe(recipe)
  local prev = currentRecipe
  currentRecipe = recipe
  
  -- populate info
  curOutput:setItem(recipe.output)
  local name = itemutil.property(recipe.output, "shortdescription") or recipe.output.name
  curName:setText(string.format("^shadow;%s", name))
  local category = itemutil.property(recipe.output, "category")
  category = category and root.assetJson("/items/categories.config").labels[category] or category or ""
  curCategory:setText(string.format("^shadow;^lightgray;%s", category))
  
  local preview = itemutil.property(recipe.output, "largeImage")
  if preview then
    preview = itemutil.relativePath(recipe.output, preview)
    curPreview:setVisible(false)
    curPreview:setFile(preview)
    -- enforce maximum width
    local sc = math.min(1, 100 / curPreview.imgSize[1])
    curPreview:setScale {sc, sc}
    curPreview:setVisible(true)
  else curPreview:setVisible(false) end
  curDescription:setText(itemutil.property(recipe.output, "extendedDescription") or itemutil.property(recipe.output, "description"))
  
  -- ingredients
  ingredientList:clearChildren()
  for _, itm in pairs(recipe.input) do
    local entry = ingredientList:addChild {
      type = "layout", mode = "horizontal", scissoring = false, children = {
        { type = "itemSlot", item = itm },
        { type = "spacer", size = -1 },
        { type = "label", text = itemutil.property(itm, "shortdescription") },
        "spacer",
        --{ type = "label", text = string.format("%d^lightgray;/^reset;%d", hasCount, itm.count), color = hasCount < itm.count and "ff3f3f" }
      }
    }
    local hint = itemutil.property(itm, "craftingHint")
    if hint then
      local tt = hint
      local h = entry:addChild {
        type = "image", file = "/interface/quests/questreceiver.png", scale = 0.5, toolTip = tt
      }
      function h:isMouseInteractable() return true end
    end
    local countLabel = entry:addChild { type = "label" }
    countLabel:subscribeEvent("updateCraftableCounts", function()
      local hasCount = hasItem(itm)
      countLabel.color = hasCount < itm.count and "ff3f3f"
      countLabel:setText(string.format("%d^lightgray;/^reset;%d", hasCount, itm.count))
    end)
    countLabel:pushEvent("updateCraftableCounts")
  end
  
  if recipe ~= prev then -- scroll up on recipe switch
    infoPane:scrollTo({0, 0}, true)
  end
end

function craftItem(recipe, count)
  if not recipe then
    pane.playSound "/sfx/interface/clickon_error.ogg"
    return nil
  end
  count = count or 1
  if not player.isAdmin() then count = math.min(count, craftableCount(recipe)) end
  if count <= 0 then
    pane.playSound "/sfx/interface/clickon_error.ogg"
    return nil
  end
  if not player.isAdmin() then
    for _, itm in pairs(recipe.input) do
      consumeItem(itm, count)
    end
  end
  player.giveItem { name = recipe.output.name, count = recipe.output.count * count, parameters = recipe.output.parameters }
  metagui.broadcast("updateCraftableCounts")
end

function btnCraft:onClick()
  craftItem(currentRecipe, tonumber(txtCount.text))
  txtCount:setText("")
end
txtCount.onEnter = btnCraft.onClick
