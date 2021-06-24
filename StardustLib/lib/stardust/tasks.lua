-- task queues

local nullFunc = function() end
local function proto() local p = { } p.__index = p return p end

local taskQueue = proto()
local task = proto()

function _ENV.taskQueue()
  local queue = setmetatable({
    tasks = { },
    byId = { },
  }, taskQueue)
  
  return queue
end

function taskQueue:run()
  local next = { }
  local idx = 1
  for _, t in pairs(self.tasks) do
    if coroutine.status(t.crt) == "dead" then t.dead = true end
    if not t.dead and not t.paused then
      _ENV.runningTask = t
      local f, err = coroutine.resume(t.crt, t) -- pass task as own argument
      if coroutine.status(t.crt) == "dead" then
        t.dead = true
        if not f then sb.logError(err) end
      end
    end
    if not t.dead then
      table.insert(next, t)
      t.index = idx
      idx = idx + 1
    else
      if t.id then self.byId[t.id] = nil end
      t:onExit()
    end
  end
  _ENV.runningTask = nil
  self.tasks = next
  if self.handleTickRate and script then script.setUpdateDelta(next[1] and 1 or 0) end
end taskQueue.__call = taskQueue.run

function taskQueue:spawn(...)
  local func, id
  for _,arg in pairs{...} do
    local t = type(arg)
    if t == "function" then func = arg
    elseif t == "string" then id = arg
    end
  end
  if not func then return nil end -- invalid
  if id and self.byId[id] then return nil end -- no dupes
  local t = setmetatable({
    queue = self,
    index = #self.tasks+1,
    id = id,
    crt = coroutine.create(func),
  }, task)
  
  self.tasks[t.index] = t
  if id then self.byId[id] = t end
  
  if self.handleTickRate and script then script.setUpdateDelta(1) end
  
  return t
end

function taskQueue:install()
  if self.installed then return self end -- don't double install
  self.installed = true
  if metagui then -- don't break shit
    mg.startEvent(function() while true do coroutine.yield() self() end end)
    return self
  end
  _ENV.update = function() self() end
  self.handleTickRate = true
  return self
end

-- marks task dead
function task:kill()
  self.dead = true
end

-- waits until task has died
function task:join()
  if not coroutine.running() then return nil end
  while not self.dead do coroutine.yield() end
end

-- same as join, except hooks onExit to immediately resume the running coroutine the moment the task dies
function task:joinImmediate()
  local crt = coroutine.running()
  if not crt then return nil end
  local ex = self.onExit
  function self:onExit()
    ex(self)
    coroutine.resume(crt)
  end
  while not self.dead do coroutine.yield() end
end

task.onExit = nullFunc
