--

-- steal tweening from dynitem
require "/lib/stardust/dynitem.lua"
local tween = dynItem.tween
dynItem = nil

movement = { }

do -- core private
  local cr, st
  local states = { }
  
  function movement.update(p)
    if not st then movement.switchState("ground") end
    local f, err = coroutine.resume(cr)
    if not f then sb.logError(err) end
  end
  
  function movement.state(name)
    if not states[name] then states[name] = { } end
    return states[name]
  end
  
  function movement.switchState(name, ...)
    if not states[name] then return nil end
    local par = {...}
    local ocr, ost = cr, st
    cr, st = nil -- preclear
    
    local nst = setmetatable({ }, { __index = states[name] })
    st = nst -- this is a separate variable for capture purposes
    
    cr = coroutine.create(function()
      -- get state changes out of the way
      if ost and ost.uninit then ost.uninit(ost) end
      if nst.init then nst.init(nst, table.unpack(par)) end
      local r = { }
      while true do
        if r[1] then
          r = { r[1](nst, table.unpack(r, 2)) }
        else
          r = { (nst.main or coroutine.yield)(nst) }
        end
      end
    end)
    
    if coroutine.running() == ocr then coroutine.resume(cr) coroutine.yield() end
  end
  
  function movement.call(fn, ...) if st and type(st[fn]) == "function" then return st[fn](st, ...) end end
end

--    --
-- -- --
--    --

do local s = movement.state("ground")
  function s:init()
    tech.setParentState()
    mcontroller.setRotation(0)
    mcontroller.clearControls()
    
    self.airJumps = 0
    sb.logInfo("started ground state")
  end
  
  function s:uninit()
    
  end
  
  function s:main()
    if input.keyDown.t1 then
      sb.logInfo("t1 press")
      for v in tween(3) do
        mcontroller.setVelocity {0, 3}
      end
    end
    
    coroutine.yield()
  end
end
