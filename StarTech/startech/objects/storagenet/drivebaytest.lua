function init(...)
    -- [[
    self.pos = object.position()
    self.dir = object.direction()
    object.smash(true)
    world.placeObject("startech:storagenet.drivebay", self.pos, self.dir)
    --]]
end

function uninit(...)
    world.placeObject("startech:storagenet.drivebay", self.pos, self.dir)
end
