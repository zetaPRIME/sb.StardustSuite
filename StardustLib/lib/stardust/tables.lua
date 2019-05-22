-- StardustLib table utility functions
tables = { }

-- merges two or more map-style tables together (insert by key)
-- modifies the first input! to perform a copy instead, have a blank table { } as first input
function tables.merge(a, b, ...)
  if not b then return a end -- done
  for k, v in pairs(b) do a[k] = v end
  return tables.merge(a, ...)
end

-- merges two or more list-style tables together (sequential keys)
-- modifies the first input! to perform a copy instead, have a blank table { } as first input
function tables.append(a, b, ...)
  if not b then return a end -- done
  for k, v in pairs(b) do table.insert(a, v) end
  return tables.merge(a, ...)
end

-- shorthand for a shallow copy
function tables.copy(t) return tables.merge({ }, t) end
