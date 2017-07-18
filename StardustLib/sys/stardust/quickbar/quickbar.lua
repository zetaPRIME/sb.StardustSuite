--




function openInterface(info)
  -- Type checking
  if type(info) == "string" then
    info = { config = root.assetJson(info) }
  elseif type(info) ~= "table" then
    sb.logError("Quickbar: Interface '%s' could not be opened. Expected a string or table.", info)
    restoreItem()
    return
  end

  -- Globally store configuration.
  if type(info.config) == "string" then
    quickbarConfig = root.assetJson(info.config)
  elseif type(info.config) == "table" then
    quickbarConfig = info.config
  end

  -- Allow dynamic modification of the loaded configuration through global 'quickbarConfig'.
  if quickbarConfig and info.loadScript then
    loadScript(info.loadScript)
  end

  -- Open interface.
  if quickbarConfig then
    player.interact(info.interactionType or "ScriptPane", quickbarConfig)
  else
    sb.logError("Quickbar: Couldn't open an interface, as no valid config was defined.\nInfo: %s", sb.printJson(info))
  end
end




local lst = "scroll.list"

local prefix = ""

function addItem(itm)
  local li = lst .. "." .. widget.addListItem(lst)
  widget.setText(li .. ".label", prefix .. itm.label)
  widget.registerMemberCallback(li .. ".buttonContainer", "click", function()
    openInterface({ config = itm.pane, loadScript = itm.loadScript })
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

function loadScript(script)
  local status, err = pcall(function() require(script) end)
  if not status then
    sb.logError("Quickbar: Failed loading '%s':\n%s", script, err)
  end
end
