skilltree = skilltree or { }

local function numStr(n, percent) -- friendly string representation of number
  if percent then n = n * 100 end
  local fn = math.floor(n)
  if math.abs(fn - n) < 0.05 then n = fn end
  return tostring(n) .. (percent and "%" or "")
end
skilltree.displayNumber = numStr

function skilltree.generateGrantToolTip(gl, name)
  local statNames = (skilltree.defs or { }).statNames or { }
  local statPercent = (skilltree.defs or { }).statPercent or { }
  
  local tt = { }
  if name then table.insert(tt, string.format("^violet;%s^reset;\n", name)) end
  for _, g in pairs(gl or { }) do
    local mode, stat, amt = table.unpack(g)
    if mode == "description" then
      table.insert(tt, string.format("%s^reset;\n", stat))
    elseif mode == "flat" then
      table.insert(tt, string.format("%s^white;%s ^cyan;%s^reset;\n", amt >= 0 and "+" or "-", numStr(math.abs(amt), statPercent[stat]), statNames[stat] or stat))
    elseif mode == "increased" then
      table.insert(tt, string.format("^white;%s%%^reset; %s ^cyan;%s^reset;\n", numStr(math.abs(amt)*100), amt >= 0 and "increased" or "decreased", statNames[stat] or stat))
    elseif mode == "more" then
      table.insert(tt, string.format("^white;%s%%^reset; %s ^cyan;%s^reset;\n", numStr(math.abs(amt)*100), amt >= 0 and "more" or "less", statNames[stat] or stat))
    end
  end
  return table.concat(tt)
end

function skilltree.generateNodeToolTip(node)
  node.toolTip = skilltree.generateGrantToolTip(node.moduleGrants or node.grants, node.moduleName or node.name)
end
