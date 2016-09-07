-- StardustLib.Sync

do
  sync = {}
  sync.queue = {}
  
  local target = false
  function sync.target(tgt)
    target = tgt
    return sync
  end
  local function msgTarget()
    return target or (pane.sourceEntity or pane.containerEntityId)()
  end
  
  function sync.poll(msg, func, ...)
    local rpc = world.sendEntityMessage(msgTarget(), msg, ...)
    if not func then return nil end -- don't bother enqueuing
    sync.queue[#(sync.queue)+1] = {
      rpc = rpc,
      func = func
    }
  end
  function sync.msg(msg, ...) return sync.poll(msg, nil, ...) end

  function sync.runQueue()
    local qi, qo = sync.queue, {}
    while qi[1] do
      local e = table.remove(qi, 1)
      if e.rpc:finished() then
        e.func(e.rpc)
      else qo[#qo+1] = e end
    end
    sync.queue = qo
  end
end
