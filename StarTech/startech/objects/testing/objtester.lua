--

function init()
  object.setInteractive(true)
end

function onInteraction()
  local theCount = (root.itemConfig({name = "stardustlib:datastore", count = 1, parameters = { dataRequest = { theCount = true } } }).parameters.dataReturn.theCount or 0) + 1
  root.itemConfig({name = "stardustlib:datastore", count = 1, parameters = { dataInsert = { theCount = theCount } } })
  
  object.say("The count is: " .. theCount)
end
