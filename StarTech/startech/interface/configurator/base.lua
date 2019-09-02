--

--require ""

local chromeCanvas = nil
ui = {}
ui.itemSlots = {}
ui.itemSlotData = {}
--ui.itemSlotLC = {}
--ui.itemSlotRC = {}

function ui.reset()
  -- TODO: finish
  widget.clearListItems("itemSlots")
  ui.itemSlots = {}
  ui.itemSlotData = {}
  
  chromeCanvas:clear()
end

function ui.resetLayout()
  startLayout(currentLayoutName)
end

local nullItem = { name = "", count = 0, parameters = {} }
local function swapItem(slot, item, rightClick, maxStack)
  -- takes item input in case something wants to modify it on the way in
  item = item or nullItem
  local si = widget.itemSlotItem(slot) or nullItem
  -- TODO: implement rightclick (and stacking-in!)
  widget.setItemSlotItem(slot, item)
  return si
end

function slotCallback(slotNum, callback, rightClick)
  local item = player.swapSlotItem() or {}
  if not item.count or item.count == 0 then item = nil end
  
  local result, maxStack = callback(item, rightClick)
  
  item = item or nullItem
  
  if result then
    player.setSwapSlotItem(swapItem(ui.itemSlots[slotNum], item, rightClick, maxStack))
    if type(result) == "function" then
      result() -- TODO: params?
    end
  end
end

function ui.addItemSlot(pos, backingImage, callback, rightClickCallback)
  -- callbacks take (cursor) item descriptor as param, return true to use default slot swap behavior (or a further callback to call something else after!)
  -- param is nil if cursor is empty
  callback = callback or function() return true end -- use default behavior if no callback specified
  rightClickCallback = rightClickCallback or callback -- use same callback for both buttons if no second callback specified
  
  local slotNum = #(ui.itemSlots) + 1
  local data = {num = slotNum, pos = pos}
  --ui.itemSlotData[slotNum] = data
  
  local li = string.format("itemSlots.%s", widget.addListItem("itemSlots"))
  data.entry = li
  local container = li .. ".container"
  widget.registerMemberCallback(container, "left", function() slotCallback(slotNum, callback) end)
  widget.registerMemberCallback(container, "right", function() slotCallback(slotNum, rightClickCallback, true) end)
  
  local slot = string.format("%s.%s.slot", container, widget.addListItem(container))
  ui.itemSlots[slotNum] = slot
  ui.itemSlotData[slot] = data
  
  if backingImage ~= false then
    -- TODO: maybe replace with an image widget within the list item? can hide/show depending on if it has something in it that way, simulating built-in background
    backingImage = backingImage or "/interface/inventory/empty.png"
    chromeCanvas:drawImage(backingImage, pos)
  end
  
  for id,d in pairs(ui.itemSlotData) do -- maybe move this to update? or maybe the end of callLayout
    widget.setPosition(d.entry, d.pos)
    widget.setSize(d.entry, {18, 18})
  end
  
  return slot
end

function ui.mainSlotItem() return widget.itemSlotItem("mainSlot") end
function ui.mainSlotSetItem(item) widget.setItemSlotItem("mainSlot", item or nullItem) end

function ui.slotItem(id)
  if type(id) == "number" then id = ui.itemSlots[id] end
  return widget.itemSlotItem(id)
end

function ui.slotSetItem(id, item)
  if type(id) == "number" then id = ui.itemSlots[id] end
  sb.logInfo("set slot " .. id .. " to " .. (item or nullItem).name)
  widget.setItemSlotItem(id, item or nullItem)
end

function ui.addLabel(pos, text, scale)
  if pos[1] then
    pos = {
      position = pos,
      verticalAnchor = "bottom"
    }
  end
  chromeCanvas:drawText(text, pos, 8 * (scale or 1))
end

layouts = {}
currentLayout = {}
currentLayoutName = ""

function getLayout(name)
  -- fetch if present
  if layouts[name] then return layouts[name] end
  
  -- else set up environment and load in the layout script
  local _glb = _ENV
  local lyt = setmetatable({ init = false, uninit = false, update = false }, {__index = _glb})
  
  layouts[name] = lyt
  __layout = lyt
  _ENV = lyt
  require(string.format("/startech/interface/configurator/layouts/%s/layout.lua", name))
  _ENV = _glb
  __layout = nil
  
  -- insert whatever layout-specific values
  lyt.basePath = string.format("/startech/interface/configurator/layouts/%s/", name) -- asset base path
  
  return lyt
end

local function callLayout(func, ...)
  -- call a function of the current layout context
  if type(currentLayout[func]) == "function" then
    local _glb = _ENV
    _ENV = currentLayout
    local ret = {_ENV[func](...)}
    _ENV = _glb
    return table.unpack(ret)
  end
end

function startLayout(name)
  callLayout("exit") -- exit current layout if not already exited
  ui.reset()
  currentLayoutName = name
  local lyt = getLayout(name)
  currentLayout = setmetatable({}, {__index = lyt})
  callLayout("init") -- and call new layout's init
end

function exitLayout()
  callLayout("exit")
  ui.reset()
end

function init()
  -- fetch configs
  startY = config.getParameter("startY")
  
  chromeCanvas = widget.bindCanvas("chromeCanvas")
  --
  
  mainSlotLeft()
end

function uninit()
  exitLayout()
  player.giveItem(widget.itemSlotItem("mainSlot") or nullItem)
end

function update(dt)
  callLayout("update", dt)
end

--

local function mainSlotSwap(rightClick)
  local item = player.swapSlotItem() or nullItem
  if not item.count or item.count == 0 then -- not trying to insert an item
    exitLayout()
    player.setSwapSlotItem(swapItem("mainSlot", item, rightClick))
    pane.dismiss()
    return nil
  end
  local cfg = root.itemConfig(item)
  local layoutName = cfg.config.configuratorLayout
  if not layoutName then return nil end
  
  exitLayout()
  player.setSwapSlotItem(swapItem("mainSlot", item, rightClick))
  startLayout(layoutName)
end
function mainSlotLeft() mainSlotSwap() end
function mainSlotRight() mainSlotSwap(true) end
