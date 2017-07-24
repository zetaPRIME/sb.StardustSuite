require("/lib/stardust/power.lua") -- hopefully this won't derp things up??

__prefab = {}
local battery = __prefab -- I don't know

function battery:new(capacity, ioRate)
  self.capacity = capacity or 10000
  ioRate = ioRate or capacity
  
  local iotype = type(ioRate)
  if iotype == "table" then self.ioRate = ioRate
  elseif iotype == "number" then self.ioRate = { input = ioRate, output = ioRate } end
  
  self.state = { energy = 0 }
end

function battery:hookUp(privateProvider, privateReceptor)
  if not privateProvider then shared.energyProvider = self end
  if not privateReceptor then shared.energyReceptor = self end
  return self
end

function battery:autoSave(key)
  key = key or "batteryState"
  if storage[key] then self.state = storage[key] else storage[key] = self.state end
  return self
end

function battery:controlTickrate()
  self.controlsTickrate = true
  return self
end

local function postUpdate(self)
  if self.controlsTickrate then
    script.setUpdateDelta((self.state.energy > 0) and 1 or 30)
  end
end

function battery:extract(socket, amount, testOnly)
  local amt = math.min(math.min(amount, self.ioRate.output), self.state.energy)
  if not testOnly then self.state.energy = self.state.energy - amt end
  postUpdate(self)
  return amt
end

function battery:receive(socket, amount, testOnly)
  local amt = math.min(math.min(amount, self.ioRate.input), self.capacity - self.state.energy)
  if not testOnly then self.state.energy = self.state.energy + amt end
  postUpdate(self)
  return amt
end

function battery:consume(amount, partial, testOnly)
  if not partial and amount > self.state.energy then return false end
  if not testOnly then self.state.energy = math.max(0, self.state.energy - amount) end
  postUpdate(self)
  return true
end
