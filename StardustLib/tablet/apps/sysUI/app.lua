_ENV = __app -- (REQUIRED) take on the environment given (can't sandbox from outside)
import "ui"

function init()
  -- start launcher, except you can't because this is before it gets focused
  -- sdos.launchApp("launcher")
end

function onFocus()
  -- switch to launcher
  sdos.launchApp("launcher")
end

function uiUpdate()
  gfx.drawText("This is the sysUI process.\nIt should have started the actual app by now.", {80, 0}, nil, {centered=true})
end

function uiPostUpdate()
  gfx.drawRect({0, 240-16, 160, 16}, {15, 15, 15})
  gfx.drawText("This is sysUI. :D", {80, 248-16}, nil, { centered = true })
end
