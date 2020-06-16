--

require "/scripts/vec2.lua"
require "/lib/stardust/playerext.lua"

local prevName

function init()
  require "/lib/stardust/configurable.lua"
  object.setInteractive(true)
  
  message.setHandler("wrenchInteract", onWrench)
  
  onSetConfig(true) -- make sure everything is in place
end

function onInteraction(args)
  if not storage or not storage.config then return nil end
  if storage.config.destination == "[normalTeleporter]" then
    return {
      "OpenTeleportDialog",
      "/interface/warping/remoteteleporter.config"
    }
  elseif storage.config.destination == "[shipTeleporter]" then
    return {
      "OpenTeleportDialog",
      "/interface/warping/shipteleporter.config"
    }
  end
  local wld = storage.config.worldId or "@@@@@"
  local dest = storage.config.destination or "OwnShip"
  local wtype = "default"
  if string.sub(dest, 0, string.len(wld)) == wld then
    dest = string.sub(dest, string.len(wld)+1)
    -- attempt instant transit
    local ep = world.getProperty("startech:telepadPosition:" .. dest:sub(19)) -- 19 because it needs to remove ":startech:telepad:"
    if ep then -- entity found! warp over directly
      playerext.setPlayer(args.sourceId).positionWarp(ep)
      return nil
    end
  end
  playerext.setPlayer(args.sourceId).warp(dest, wtype) -- formerly "beam"; turns out that's not actually what normal teleporters use
end

function onWrench(msg, isLocal, player, shiftHeld)
  if storage.config.lock and storage.config.lock ~= world.entityUniqueId(player) then
    object.say(string.format("^red;Access denied.^reset;\n^lightgray;Locked by ^cyan;%s^lightgray;.^reset;", storage.config.lockName or ("player " .. storage.config.lock)))
    return nil
  end
  
  if shiftHeld then -- quick break a la modded-Minecraft
    object.smash()
    return nil
  end
  
  return { -- open interface
    interact = {
      id = entity.id(),
      type = "ScriptPane",
      config = { gui = { }, scripts = {"/metagui.lua"}, config = "startech:telepad.config" }
    }
  }
end

function onSetConfig(skipName)
  -- try to set unique ID
  local function trySetId(name)
    local uid = string.format("startech:telepad:%s", name)
    local iid = world.loadUniqueEntity(uid)
    if iid and iid > 0 and iid ~= entity.id() then return false end -- fail; already taken by something else
    object.setUniqueId(uid)
    return true
  end
  
  -- handle name collisions
  if not skipName then
    if not storage.config.name then
      object.setUniqueId(nil) -- nothing there
    else
      local name = storage.config.name
      if not trySetId(name) then
        local lname = ""
        local i = 1
        while true do
          i = i + 1
          lname = string.format("%s (%i)", name, i)
          if trySetId(lname) then break end
        end
        storage.config.name = lname
      end
    end
  end
  
  -- handle position tracking
  if prevName then
    world.setProperty("startech:telepadPosition:" .. prevName, nil)
  end
  if storage.config.name then
    world.setProperty("startech:telepadPosition:" .. storage.config.name, vec2.add(entity.position(), config.getParameter("teleporterFootPosition") or {0, 0}))
  end
  prevName = storage.config.name
  
  -- set description
  if not storage.config.destination then
    object.setConfigParameter("description", "A telepad.\n^lightgray;No link configured.^reset;")
  elseif storage.config.destination == "[normalTeleporter]" then
    object.setConfigParameter("description", "A telepad.\n^lightgray;Configured as a normal teleporter.^reset;")
  elseif storage.config.destination == "[shipTeleporter]" then
    object.setConfigParameter("description", "A telepad.\n^lightgray;Configured as a ship teleporter.^reset;")
  else
    object.setConfigParameter("description", string.format("A telepad.\n^lightgray;Linked to ^cyan;%s^lightgray;.^reset;", storage.config.destinationName or storage.config.destination))
  end
  
  --
end

function die()
  if storage.config.name then
    world.setProperty("startech:telepadPosition:" .. storage.config.name, nil)
  end
end













--
