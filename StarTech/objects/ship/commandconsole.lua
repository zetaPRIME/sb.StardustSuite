
--

function init()
  if not storage.invert then storage.invert = false end
  
  message.setHandler("wrenchInteract", wrenchInteract)
end

lastLounged = false
function update()
  local lounged = world.loungeableOccupied(entity.id())
  
  if lounged ~= lastLounged then
    local o = lounged
    if storage.invert then o = not o end
    object.setOutputNodeLevel(0, o)
  end
  lastLounged = lounged
end

function wrenchInteract(msg, isLocal, shift)
  storage.invert = not storage.invert
  lastLounged = 42
  object.say("Invert output: " .. (storage.invert and "on" or "off"))
end

function nonInteraction(args)
  object.say(dump(args))
end

function dump(o, ind)
  if not ind then ind = 2 end
  local pfx, epfx = "", ""
  for i=1,ind do pfx = pfx .. " " end
  for i=3,ind do epfx = epfx .. " " end
  if type(o) == 'table' then
    local s = '{\n'
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. pfx .. '['..k..'] = ' .. dump(v, ind+2) .. ',\n'
    end
    return s .. epfx .. '}'
  else
    return tostring(o)
  end
end
