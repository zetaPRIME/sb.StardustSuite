-- input module, you know what this does

input = {
  key = { },
  keyLast = { },
  keyDown = { },
  keyUp = { }
}

function input.update(p)
  local m = p.moves
  --sb.logInfo(util.tableToString(m))
  input.keyLast = input.key -- push back
  input.key = { -- assemble keys
    up = m.up, down = m.down, left = m.left, right = m.right,
    jump = m.jump, sprint = not m.run,
    t1 = m.special1, t2 = m.special2, t3 = m.special3,
    m1 = m.primaryFire, m2 = m.altFire,
  }
  for k in pairs(input.key) do
    input.keyDown[k] = input.key[k] and not input.keyLast[k]
    input.keyUp[k] = input.keyLast[k] and not input.key[k]
  end
  -- I think that's everything
end
