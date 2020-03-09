--

function init()
  object.setInteractive(true)
end

function onInteraction()
  local m = getmetatable('')
  m.theCount = (m.theCount or 0) + 1
  object.say("The count is: " .. m.theCount)
end
