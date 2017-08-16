--

require "/lib/stardust/sync.lua"

cfg = {name="Test"}
bookmarks = {}

function createBookmark()
  if not cfg.name or cfg.name == "" then return nil end -- can't bookmark an unnamed pad!
  local b = {}
  
  local wid = player.worldId()
  
  b.destination = string.format("%s=startech:telepad:%s", wid, cfg.name)
  b.name = cfg.name
  -- TODO: world name, icon
  local wc = string.find(wid, ":")
  local wtype = string.sub(wid, 0, wc-1)
  local wsub = string.sub(wid, wc+1)
  if wtype == "CelestialWorld" then
    b.icon = string.format("/interface/bookmarks/icons/%s.png", world.type())
    b.desc = celestial.planetName(wsub)
  elseif wtype == "ClientShipWorld" then
    b.icon = "/interface/bookmarks/icons/ship.png"
    b.desc = "Player Ship"
  else
    local wsc = string.find(wsub, ":")
    local wstype = string.sub(wsub, 0, wsc-1)
    
    local sysObj = root.assetJson("/system_objects.config")
    
    local o = sysObj[wstype]
    if o and o.parameters then
      if o.parameters.bookmarkIcon then
        b.icon = string.format("/interface/bookmarks/icons/%s.png", o.parameters.bookmarkIcon)
      else
        b.icon = o.parameters.icon
      end
      b.desc = o.parameters.displayName
    else
      b.icon = ""
      b.desc = "Unknown world"
    end
    
    --
  end
  
  --b.name = b.destination
  
  bookmarks[b.destination] = b
  status.setStatusProperty("startech:telepadBookmarks", bookmarks)
  
  uiUpdateList()
  
  -- manually fix selection here because it's temperamental
  local sel = listEntries[cfg.destination or "NULL"]
  if sel then
    widget.setListSelected("bookmarks.list", sel.key)
  end
end

function deleteBookmark(destination)
  bookmarks[destination] = nil
  status.setStatusProperty("startech:telepadBookmarks", bookmarks)
  
  uiUpdateList()
end

function init()
  bookmarks = status.statusProperty("startech:telepadBookmarks", {})
  uiUpdateList()
  
  sync.poll("getConfig", onRecvConfig)
  
  
end

function update()
  sync.runQueue()
end

function uiListSelect(target)
  
end

function uiListOnSelect()
  --local ind = widget.getListSelected("bookmarks.list")
  --widget.setText("lblLock", "sel" .. listEntries[ind].index)
  
  uiChanged() -- update config with destination
end

function uiUpdateList()
  listEntries = { }
  widget.clearListItems("bookmarks.list")
  
  local function addEntry(par)
    local e = { }
    e.index = #listEntries + 1
    e.key = widget.addListItem("bookmarks.list")
    e.path = "bookmarks.list." .. e.key
    e.system = par.system or false
    e.destination = par.destination
    e.name = par.name or "???"
    e.desc = par.desc or ""
    e.icon = par.icon or ""
    
    -- index numerically, by generated widget name, and by destination
    listEntries[e.index] = e
    listEntries[e.key] = e
    listEntries[e.destination or false] = e
    
    widget.setText(e.path .. ".name", e.name)
    widget.setText(e.path .. ".desc", e.desc)
    widget.setImage(e.path .. ".icon", e.icon)
  end
  
  -- hardcoded entries
  addEntry({
    destination = nil,
    name = "Beam to own ship",
    desc = "(No destination set)",
    icon = "/interface/bookmarks/icons/beamup.png",
    system = true
  })
  addEntry({
    destination = "[normalTeleporter]",
    name = "Standard mode",
    desc = "Use as normal teleporter",
    icon = "/objects/tech/teleporters/telepad.icon.png",
    system = true
  })
  addEntry({
    destination = "[shipTeleporter]",
    name = "Ship mode",
    desc = "Use as ship teleporter",
    icon = "/interface/bookmarks/icons/ship.png",
    system = true
  })
  
  for k, v in pairs(bookmarks) do
    addEntry(v) -- wait, they just plain use the same format
  end
end

function uiChanged()
  dirty = true
  
  -- write UI state into config
  cfg.name = widget.getText("txtName")
  if cfg.name == "" then cfg.name = nil end
  
  local sel = listEntries[widget.getListSelected("bookmarks.list")]
  if sel then
    cfg.destination = sel.destination
    cfg.destinationName = sel.name
  end
  
  if widget.getChecked("chkLock") then
    cfg.lock = player.uniqueId()
    cfg.lockName = world.entityName(player.id())
  else
    cfg.lock = nil
    cfg.lockName = nil
  end
  
  uiPostUpdate()
end

function uiPostUpdate()
  widget.setButtonEnabled("btnCreateBookmark", cfg.name == setName and cfg.name ~= nil)
  
  local sel = listEntries[widget.getListSelected("bookmarks.list")]
  widget.setButtonEnabled("btnDeleteBookmark", sel and not sel.system)
end

function uiUnfocus()
  widget.focus("txtName")
  widget.blur("txtName")
end

function applyChanges()
  uiChanged() -- make sure cfg is current
  
  sync.poll("setConfig", onRecvConfig, cfg)
end

function revertChanges()
  -- for some non-reason it's simply incapable of updating the list selection after updating a textbox's contents!?
  local function r(...)
    uiUpdateList() -- unless I force the matter by rebuilding the list first
    onRecvConfig(...)
  end
  sync.poll("getConfig", r)
end

function btnCreateBookmark()
  if cfg.name == setName and cfg.name ~= nil then
    createBookmark() -- create bookmark of current telepad
  end
end

function btnDeleteBookmark()
  local sel = listEntries[widget.getListSelected("bookmarks.list")]
  if sel then
    deleteBookmark(sel.destination)
  end
end

function onRecvConfig(rpc)
  if not rpc:succeeded() then return nil end
  cfg = rpc:result()
  
  -- update UI
  uiUnfocus()
  widget.setText("txtName", cfg.name or "")
  widget.setChecked("chkLock", not not cfg.lock)
  
  local sel = listEntries[cfg.destination or false]
  if sel then
    widget.setListSelected("bookmarks.list", sel.key)
  end
  
  dirty = false
  setName = cfg.name
  
  uiPostUpdate()
end

















--
