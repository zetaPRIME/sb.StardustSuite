skilltree = skilltree or { }

function skilltree.calculateFinalStat(s)
  if not s then return 0 end
  return s[1] * s[2] * s[3] -- not hard, just, y'know
end
