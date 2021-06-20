-- task queues

local nullFunc = function() end

local taskQueue = { }
local taskQueueMeta = { __index = taskQueue }
local task = { }
local taskMeta = { __index = task }

function _ENV.taskQueue()
  local queue = setmetatable({
    tasks = { },
    byId = { },
  }, taskQueueMeta)
  
  return queue
end

function taskQueue:run()
  local next = { }
  local idx = 1
  for _, t in pairs(self.tasks) do
    if coroutine.status(t.crt) == "dead" then t.dead = true end
    if not t.dead and not t.paused then
      _ENV.runningTask = t
      local f, err = coroutine.resume(t.crt)
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
end

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
  }, taskMeta)
  
  self.tasks[t.index] = t
  if id then self.byId[id] = t end
  
  return t
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
