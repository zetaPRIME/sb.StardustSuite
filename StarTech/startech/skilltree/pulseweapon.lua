-- helper for pulse wepapon stat displays

function skilltree.modifyStatDisplay.punchthrough(txt, v)
  if v == 0 then return "" end
  local s = v ~= 1.0 and "s" or ""
  return string.format("%s ^lightgray;tile%s of ^cyan;punchthrough^reset;", skilltree.displayNumber(v), s)
end
