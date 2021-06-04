-- Telepad configuration panel

local function waitFor(p) -- wait for promise
  while not p:finished() do coroutine.yield() end
  return p
end

bookmarks = player.getProperty("startech:telepadBookmarks", { })

local lock = true
local cfg, setCfg
metagui.startEvent(function() -- load config
  cfg = waitFor(world.sendEntityMessage(pane.sourceEntity(), "getConfig")):result()
  setCfg = util.mergeTable({ }, cfg) -- copy
  
  -- fill out stats
  nameField:setText(cfg.name)
  lockCheck:setChecked(not not cfg.lock)
  buildList()
  lock = false
end)

local function onItemSelected(w)
  local e = w.entry
  cfg.destination = e.destination
  cfg.destinationName = e.name
end
local function onItemClick(w, btn)
  if btn == 2 then
    if lock or w.entry.system then return nil end -- can't delete system entries
    metagui.contextMenu {
      { "Delete bookmark", function()
        local e = w.entry
        bookmarks[e.destination] = nil
        player.setProperty("startech:telepadBookmarks", bookmarks)
        cfg.destination, cfg.destinationName = setCfg.destination, setCfg.destinationName -- reset
        buildList()
      end }
    }
  end
end

function buildList()
  selectedEntry = nil
  bookmarkList:clearChildren()
  
  local function addEntry(par)
    local e = {
      system = par.system or false,
      destination = par.destination,
      name = par.name or "???",
      desc = par.desc or "",
      icon = par.icon or "",
    }
    
    -- create entry widget
    local w = bookmarkList:addChild {
      type = "listItem", children = {
        { mode = "horizontal" },
        { type = "image", size = {18, 18}, file = e.icon },
        {
          { type = "label", text = e.name },
          { type = "label", text = e.desc, color = "bfbfbf" },
        }
      }
    }
    w.entry = e
    if e.destination == cfg.destination then w:select() end
    w.onSelected = onItemSelected
    w.onClick = onItemClick
  end
  
  -- system entries
  addEntry {
    destination = nil,
    name = "Beam to own ship",
    desc = "(No destination set)",
    icon = "/interface/bookmarks/icons/beamup.png",
    system = true
  }
  addEntry {
    destination = "[normalTeleporter]",
    name = "Standard mode",
    desc = "Use as normal teleporter",
    icon = "/startech/objects/teleporters/telepad.icon.png",
    system = true
  }
  addEntry {
    destination = "[shipTeleporter]",
    name = "Ship mode",
    desc = "Use as ship teleporter",
    icon = "/interface/bookmarks/icons/ship.png",
    system = true
  }
  -- and populate bookmarks
  for k, v in pairs(bookmarks) do addEntry(v) end
end

function apply:onClick()
  if lock then
    return theme.errorSound()
  end
  
  cfg.name = nameField.text
  if cfg.name == "" then cfg.name = nil end
  if lockCheck.checked then
    cfg.lock = player.uniqueId()
    cfg.lockName = world.entityName(player.id())
  else
    cfg.lock = nil
    cfg.lockName = nil
  end
  cfg.worldId = player.worldId()
  
  lock = true
  waitFor(world.sendEntityMessage(pane.sourceEntity(), "setConfig", cfg))
  setCfg = util.mergeTable({ }, cfg) -- copy
  lock = false
end

function newBookmark:onClick()
  if lock or nameField.text ~= cfg.name or cfg.name ~= setCfg.name or not cfg.name then
    return theme.errorSound()
  end
  
  local b = { }
  local wid = player.worldId()
  
  b.destination = string.format("%s=startech:telepad:%s", wid, cfg.name)
  b.name = cfg.name
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
  end
  
  bookmarks[b.destination] = b
  player.setProperty("startech:telepadBookmarks", bookmarks)
  
  buildList()
end
