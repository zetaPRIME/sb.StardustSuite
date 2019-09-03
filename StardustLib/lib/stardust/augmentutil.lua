-- things

require "/scripts/util.lua"

augmentUtil = { }

local augmap

function augmentUtil.extract(itm, modify)
  if not itm or not itm.parameters or not itm.parameters.currentAugment then return nil end
  
  if not augmap then
    augmap = { } -- build dictionary from multiple sources
    util.mergeTable(augmap, root.assetJson("/lib/stardust/augmentdefs.config").typeToItem)
    local aex = root.itemConfig("aex") -- take advantage of augment extractor if present
    if aex then util.mergeTable(augmap, aex.config.augmentMap) end
  end
  
  local aug = itm.parameters.currentAugment
  if not augmap[aug.name] then return false end -- don't try to remove an unknown augment
  
  if modify then itm.parameters.currentAugment = nil end -- delete augment from item if set to modify
  return { name = augmap[aug.name], count = 1, parameters = { } } -- and return descriptor
end
