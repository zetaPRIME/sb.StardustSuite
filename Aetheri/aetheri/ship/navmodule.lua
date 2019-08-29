-- Aetheri module for nav console

local si = navExt.stockIcons

local apPerFuel = 5

bottomBar:addWidget{
  type = "button", icon = "/items/currency/essence.png?crop=1;2;14;16",
  toolTip = function()
    if player.worldId() ~= player.ownShipWorldId() then return "^red;Cannot infuse outside of ship" end
    local fuelNeeded = world.getProperty("ship.maxFuel", 0) - world.getProperty("ship.fuel", 0)
    if fuelNeeded <= 0 then return "^gray;No fuel needed" end
    local apTaken = math.min(fuelNeeded * apPerFuel, status.statusProperty("aetheri:AP", 0))
    return string.format("Infuse %iAP ^lightgray;(%iAP/fuel)", math.floor(0.5 + apTaken), apPerFuel)
  end,
  callback = function()
    if player.worldId() ~= player.ownShipWorldId() then pane.playSound("/sfx/interface/clickon_error.ogg") return nil end
    local fuelNeeded = world.getProperty("ship.maxFuel", 0) - world.getProperty("ship.fuel", 0)
    if fuelNeeded <= 0 then return nil end
    local ap = status.statusProperty("aetheri:AP", 0)
    local apTaken = math.min(fuelNeeded * apPerFuel, ap)
    status.setStatusProperty("aetheri:AP", ap - apTaken)
    world.setProperty("ship.fuel", world.getProperty("ship.fuel", 0) + (apTaken / apPerFuel))
    pane.playSound("/sfx/objects/essencechest_open3.ogg")
  end,
}

si.openSAIL()
si.teleporter()

function speciesUpdate()
  
end
