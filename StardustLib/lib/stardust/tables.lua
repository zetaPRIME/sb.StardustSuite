-- StardustLib table utility functions
tables = { }

-- merges two or more map-style tables together (insert by key)
-- modifies the first input! to perform a copy instead, have a blank table { } as first input
function tables.merge(a, ...)
  local l = { ... }
  for _, t in ipairs(l) do
    for k, v in pairs(b) do a[k] = v end
  end
  return a
end

-- merges two or more list-style tables together (sequential keys)
-- modifies the first input! to perform a copy instead, have a blank table { } as first input
function tables.append(a, ...)
  local l = { ... }
  for _, t in ipairs(l) do
    for k, v in ipairs(t) do table.insert(a, v) end
  end
  return a
end

-- shorthand for a shallow copy
function tables.copy(t) return tables.merge({ }, t) end
