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
  local function entrySort(a, b)
    local sa, sb = (a.sortId or a.name), (b.sortId or b.name)
    if sa == sb then
      return a.name < b.name
    end return sa < sb
  end
  
  local function onRecipeSelected(self)
    recipeList:pushEvent("listItemSelected", self)
    selectRecipe(self.recipe)
  end
  
  
  -- assemble sorted section list
  local sections = { }
  for sid, section in pairs(recipeData.sections) do
    section.id = sid
    section.sortId = section.sortId or recipeData.defaultSectionSortId
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
      recipe.sortId = recipe.sortId or section.defaultSortId or recipeData.defaultRecipeSortId
      normalizeItem(recipe.output)
      for _, itm in pairs(recipe.input) do normalizeItem(itm) end
      recipe.name = itemutil.property(recipe.output, "shortdescription")
      table.insert(recipes, recipe)
    end table.sort(recipes, entrySort)
    
    if not recipes[1] then
      subList:addChild { type = "layout", mode = "horizontal", size = {0, 16}, expandMode = {2, 0}, align = 0.5, children = {
        { type = "label", align = "center", text = "^gray;(no recipes unlocked)" }
      } }
    end
    
    for _, recipe in pairs(recipes) do
      --if not currentRecipe then currentRecipe = recipe end
      local listItem = subList:addChild { type = "listItem", size = {200, 42}, children = { { mode = "vertical", scissoring = false } } }
      listItem.recipe = recipe
      listItem.onSelected = onRecipeSelected
      
      -- populate info rows
      local topRow = listItem:addChild { type = "layout", mode = "horizontal", align = 0.5, scissoring = false }
      local bottomRow = listItem:addChild { type = "layout", mode = "horizontal", align = 0.5, scissoring = false }
      
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
      
      --bottomRow:addChild { type = "image", file = "/interface/objectcrafting/arrow.png" }
      bottomRow:addChild { type = "label", text = "^gray;>", inline = true }
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
  
  -- preview stuff
  function getScale(size, obj)
    local min, max = {70, 45}, {100, 45}
    if obj then max = min end
    local s = 1
    s = math.max(s, min[1]/size[1])
    s = math.max(s, min[2]/size[2])
    s = math.min(s, max[1]/size[1])
    s = math.min(s, max[2]/size[2])
    return {s, s}
  end
  previewArea:clearChildren()
  local padding = { type = "spacer", size = 3 }
  local orientation = itemutil.property(recipe.output, "orientations") orientation = orientation and orientation[1]
  local preview = itemutil.property(recipe.output, "largeImage")
  if orientation and not preview then
    if type(orientation.image) == "string" then preview = orientation.image
    elseif orientation.dualImage then
      preview = orientation.dualImage .. "?flipx"
    elseif orientation.imageLayers then
      preview = util.mergeTable({ }, orientation.imageLayers)
    end
  end
  if not preview then preview = itemutil.property(recipe.output, "inventoryIcon") end
  if type(preview) == "string" then -- single image
    preview = itemutil.relativePath(recipe.output, preview)
    previewArea:addChild(padding)
    local curPreview = previewArea:addChild { type = "image" }
    previewArea:addChild(padding)
    curPreview:setFile(preview)
    -- enforce maximum width
    curPreview:setScale(getScale(curPreview.imgSize, orientation))
  elseif type(preview) == "table" then -- composite
    local bb = {math.huge, math.huge, -math.huge, -math.huge}
    for _, l in pairs(preview) do
      l.image = itemutil.relativePath(recipe.output, l.image)
      local r = rect.translate(root.nonEmptyRegion(l.image), l.offset or {0, 0})
      bb[1] = math.min(bb[1], r[1]) bb[2] = math.min(bb[2], r[2]) bb[3] = math.max(bb[3], r[3]) bb[4] = math.max(bb[4], r[4])
    end
    local off = vec2.mul(rect.ll(bb), -1)
    local scale = getScale(rect.size(bb), orientation)
    
    previewArea:addChild(padding)
    local img = previewArea:addChild { type = "layout", mode = "manual", size = vec2.mul(rect.size(bb), scale) }
    previewArea:addChild(padding)
    for _, l in pairs(preview) do
      img:addChild { type = "image", file = l.image, noAutoCrop = true, position = vec2.mul(vec2.mul(vec2.add(off, l.offset or {0, 0}), {1, -1}), scale), scale = scale }
    end
  end
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
