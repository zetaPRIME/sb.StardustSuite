function makeRNG(...)
  local rng = { }
  rng.seed = sb.staticRandomI32(...)
  
  function rng.advance() rng.seed = sb.staticRandomI32(rng.seed) end
  
  function rng.int(min, max)
    rng.advance()
    if not max then return sb.staticRandomI32() end
    return sb.staticRandomI32Range(min, max, rng.seed)
  end
  
  function rng.float(min, max)
    rng.advance()
    if not max then return sb.staticRandomDouble() end
    return sb.staticRandomDoubleRange(min, max, rng.seed)
  end
  
  return rng
end
