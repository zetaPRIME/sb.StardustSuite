-- helper for pulse wepapon stat displays

function skilltree.modifyStatDisplay.damage(txt, v)
  local tier = v*2 - 1
  return txt .. string.format(" ^lightgray;(tier ^white;%s^lightgray;)^reset;", skilltree.displayNumber(tier))
end
function skilltree.modifyStatDisplay.charge(txt, v)
  return v ~= 1.0 and txt or ""
end

function skilltree.modifyStatDisplay.dps(txt, v)
  local dmg = skilltree.calculateFinalStat(skilltree.displayStats.damage)
  local spd = skilltree.calculateFinalStat(skilltree.displayStats.speed)
  local dps = dmg * spd
  local tier = dps*2 - 1
  return string.format("^lightgray;(^white;%s ^cyan;DPS^lightgray;, tier ^white;%s^lightgray;)^reset;", skilltree.displayNumber(dps, true), skilltree.displayNumber(tier))
end

function skilltree.modifyStatDisplay.punchthrough(txt, v)
  if v == 0 then return "" end
  local s = v ~= 1.0 and "s" or ""
  return string.format("%s ^lightgray;tile%s of ^cyan;punchthrough^reset;", skilltree.displayNumber(v), s)
end
