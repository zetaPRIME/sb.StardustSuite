require "/scripts/rails.lua"

require "/lib/stardust/mechanism.lua"

function init()
  mcontroller.setRotation(0)

  self.worldBottomDeathLevel = 5

  local railConfig = config.getParameter("railConfig", {})
  railConfig.facing = config.getParameter("initialFacing", 1)

  self.railRider = Rails.createRider(railConfig)
  self.railRider:init(storage.railStateData)

  self.popOnInteract = config.getParameter("popOnInteract", true)
  updateInteractive()
end

function onInteraction(args)
  if mechanism.entityHoldingWrench(args.sourceId) then popVehicle() end
end

function update(dt)
  if mcontroller.position()[2] < self.worldBottomDeathLevel then
    vehicle.destroy()
    return
  end

  if mcontroller.isColliding() then
    popVehicle()
  else
    self.railRider:update(dt)
    storage.railStateData = self.railRider:stateData()
    updateInteractive()
  end
end

function uninit()
  self.railRider:uninit()
end

function updateInteractive()
  vehicle.setInteractive(self.popOnInteract and not world.isTileProtected(mcontroller.position()))
end

function popVehicle()
  local popItem = config.getParameter("popItem")
  if popItem then
    world.spawnItem(popItem, entity.position(), 1)
  end
  vehicle.destroy()
end
