require "/lib/stardust/eventhook.lua"

local hd = sharedTable "stardustlib:hudData"

--[[function update(...)
  localAnimator.clearDrawables()
  
  if hd.targetPos then
    localAnimator.addDrawable({
      position = hd.targetPos,
      image = string.format("/sys/stardust/hud/hud1.png:%s", "7"),
      fullbright = true
    }, "foregroundEntity+4")
    hd.targetPos = nil
  end
end]]

function init()
  --
  
  eventHook.subscribe("lolwut")
  eventHook.call("lolwut")
end

--setmetatable(_ENV, {__index = function(_, n) sb.logInfo("unknown func " .. n) end})
