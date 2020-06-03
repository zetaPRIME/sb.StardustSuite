require "/lib/stardust/itemutil.lua"

skilltree = skilltree or { }

local needsRedraw = true
local skillData, itemData, saveData

function skilltree.init(canvas, treePath, data, saveFunc)
  saveData = saveFunc
  skillData = data or { }
  skilltree.canvasWidget = canvas
  skilltree.canvas = widget.bindCanvas(canvas.backingWidget)
  skilltree.initUI()
end

function skilltree.initFromItem(canvas, loadItem, saveItem)
  itemData = ((type(loadItem) == "table") and loadItem) or loadItem()
  local treePath = itemutil.property(itemData, "stardustlib:skillTree")
  
  --itemData["stardustlib:skillData"] = itemData["stardustlib:skillData"] or { }
  skilltree.init(canvas, treePath, itemData["stardustlib:skillData"], function(data)
    itemData["stardustlib:skillData"] = data
    saveItem(itemData)
  end)
end

function skilltree.redraw() needsRedraw = true end

function skilltree.saveChanges()
  -- TODO calculate stuffs!
  saveData(skillData)
end

function skilltree.draw()
  needsRedraw = false
  local c = skilltree.canvas
  c:clear()
  local s = c:size()
  c:drawRect({0, 0, s[1], s[2]}, {0, 0, 0})
  metagui.setTitle("drawn")
end

function skilltree.initUI()
  local w = skilltree.canvasWidget
  metagui.startEvent(function()
    while true do
      metagui.setTitle("bleg")
      if true or needsRedraw then skilltree.draw() end
      coroutine.yield()
    end
  end)
end
