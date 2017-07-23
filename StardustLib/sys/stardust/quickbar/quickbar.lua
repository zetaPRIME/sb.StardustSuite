--




function openInterface(info)
  if type(info) ~= "table" then info = {config = info} end
  player.interact(info.interactionType or "ScriptPane", info.config or "/sys/stardust/tablet/tablet.ui.config")
end




modules = {}

local function handleClick(itm)
  if itm.scriptAction then -- scripted action specified
    local ci = string.find(itm.scriptAction, ":")
    local module = string.sub(itm.scriptAction, 1, ci-1)
    local action = string.sub(itm.scriptAction, ci+1)
    
    if not modules[module] then
      modules[module] = {} -- initialize module table and load in the appropriate script
      _ENV.module = modules[module] -- allow code to be less dependent on filename
      require(string.format("/quickbar/%s.lua", module))
      _ENV.module = nil
    end
    
    if modules[module][action] then
      modules[module][action](itm) -- trigger script action, passing in the item table
    end
  elseif itm.pane then openInterface(itm.pane) end
end

local lst = "scroll.list"

local prefix = ""

local function addItem(itm)
  local li = lst .. "." .. widget.addListItem(lst)
  widget.setText(li .. ".label", prefix .. itm.label)
  widget.registerMemberCallback(li .. ".buttonContainer", "click", function()
    handleClick(itm)
  end)
  local btn = li .. ".buttonContainer." .. widget.addListItem(li .. ".buttonContainer") .. ".button"
  if itm.icon then
    local icn = itm.icon
    if icn:sub(1,1) ~= "/" then icn = "/quickbar/" .. icn end
    widget.setButtonOverlayImage(btn, itm.icon)
  end
end

local items = {}
local autoRefreshRate = 0
local autoRefreshTimer = 0
function init()
  items = root.assetJson("/quickbar/icons.json") or {}
  refresh()
  
  autoRefreshRate = config.getParameter("autoRefreshRate")
  autoRefreshTimer = autoRefreshRate
end

function refresh()
  widget.clearListItems(lst)
  prefix = "^#7fff7f;"
  for k,v in pairs(items.priority or {}) do addItem(v) end
  if player.isAdmin() then
    prefix = "^#bf7fff;"
    for k,v in pairs(items.admin or {}) do addItem(v) end
  end
  prefix = ""
  for k,v in pairs(items.normal or {}) do addItem(v) end
end

function update(dt)
  autoRefreshTimer = math.max(0, autoRefreshTimer - dt)
  if autoRefreshTimer == 0 then
    autoRefreshTimer = autoRefreshRate
    --refresh() -- whoops, that just kind of derps things up :(
  end
end
