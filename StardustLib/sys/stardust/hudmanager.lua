local hd = { }
getmetatable''["stardustlib:hudData"] = hd

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
end

--setmetatable(_ENV, {__index = function(_, n) sb.logInfo("unknown func " .. n) end})
