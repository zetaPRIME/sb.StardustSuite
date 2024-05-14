-- monkey-patching the hook into every container
function patch(o, path)
  if not o.gui then return o end -- not a pane config
  
  local found = false
  for k,v in pairs(o.gui) do
    if v.type == "itemgrid" then
      found = true
      break
    end
  end
  if not found then return o end -- no item grid, not a container pane
  
  if not o.scripts then o.scripts = { } end
  table.insert(o.scripts, "/stardustui/containerhook.lua")
  
  return o
end
