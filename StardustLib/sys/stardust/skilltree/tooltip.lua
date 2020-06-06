skilltree = skilltree or { }

local function numStr(n) -- friendly string representation of number
  local fn = math.floor(n)
  if math.abs(fn - n) < 0.05 then return tostring(fn) else return tostring(n) end
end

function skilltree.generateGrantToolTip(gl, name)
  if not statNames then statNames = root.assetJson("/aetheri/species/skilltree.config:statNames") end
  
  local tt = { }
  if name then table.insert(tt, string.format("^violet;%s^reset;\n", name)) end
  for _, g in pairs(gl or { }) do
    local mode, stat, amt = table.unpack(g)
    if mode == "description" then
      table.insert(tt, string.format("%s^reset;\n", stat))
    elseif mode == "flat" then
      table.insert(tt, string.format("%s^white;%s ^cyan;%s^reset;\n", amt >= 0 and "+" or "-", numStr(math.abs(amt)), statNames[stat] or stat))
    elseif mode == "increased" then
      table.insert(tt, string.format("^white;%s%%^reset; %s ^cyan;%s^reset;\n", numStr(math.abs(amt)*100), amt >= 0 and "increased" or "decreased", statNames[stat] or stat))
    elseif mode == "more" then
      table.insert(tt, string.format("^white;%s%%^reset; %s ^cyan;%s^reset;\n", numStr(math.abs(amt)*100), amt >= 0 and "more" or "less", statNames[stat] or stat))
    end
  end
  return table.concat(tt)
end

function skilltree.generateNodeToolTip(node)
  node.toolTip = generateGrantToolTip(node.grants, node.name)
end
