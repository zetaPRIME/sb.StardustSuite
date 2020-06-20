--

require "/lib/stardust/itemutil.lua"
require "/lib/stardust/color.lua"
require "/lib/stardust/augmentutil.lua"

local cfgItem, syncId

function init()
  cfgItem = player.swapSlotItem()
  if not cfgItem or cfgItem.name ~= "startech:augpack" then return pane.dismiss() end
  player.setSwapSlotItem()
  
  if cfgItem.parameters.insertedItems then -- migrate old augpack
    -- refund inserted items
    for _, itm in pairs(cfgItem.parameters.insertedItems) do
      player.giveItem(itm)
    end
    local fp = cfgItem.parameters.batteryStats and cfgItem.parameters.batteryStats.energy or 0
    cfgItem.parameters = { -- reinitialize fully.
      inventory = { cell = { name = "startech:battery.t2", count = 1, parameters = { } } }, -- consolation prize of a bigger cell!
      batteryStats = { energy = fp } -- retain charge too
    }
  end
  
  syncId = sb.makeUuid()
  cfgItem.parameters.syncId = syncId
  
  do -- populate item slots
    local inv = cfgItem.parameters.inventory or { }
    cellSlot:setItem(inv.cell)
    packSlot:setItem(inv.pack)
    augmentSlot:setItem(inv.augment)
  end
  
  local backItem = player.equippedItem("back")
  if backItem then
    if not packSlot:item() and packSlot:acceptsItem(backItem) then
      packSlot:setItem(backItem) packSlot:onItemModified()
    else player.giveItem(backItem) end
  end
  
  lightCheck:setChecked(cfgItem.parameters.lightEnabled)
  
  player.setEquippedItem("back", cfgItem)
  updateCell()
  saveItem()
end

function updateCell()
  local cell = cellSlot:item()
  if not cell then return nil end
  local cfgItem = player.equippedItem("back")
  
  local fp = cfgItem.parameters.batteryStats and cfgItem.parameters.batteryStats.energy or 0
  if cell.parameters.storedEnergy == fp then return nil end -- no need to update
  cell.parameters.storedEnergy = fp
  local capacity = itemutil.property(cell, "/batteryStats/capacity")
  -- set description
  cell.parameters.description = string.format("%s\n^green;%d^darkgreen;/^green;%d^darkgreen;FP^reset;",
    itemutil.property(cell, "/baseDescription"), math.floor(fp), math.floor(capacity)
  )
  -- build icon (TODO: do this stuff in a builder instead)
  local batLevel = fp / capacity
  cell.parameters.inventoryIcon = {
    { image = itemutil.property(cell, "/iconBaseImage") or "battery.frame.png" },
    {
      image = table.concat({
        "battery.meter.png?addmask=/startech/objects/power/battery.meter.png", ";0;",
        10 - math.floor(batLevel * 10),
        "?multiply=", color.toHex(color.fromHsl{math.max(0, batLevel*1.25 - 0.25) * 1/3, 1, 0.5, 1})
      }),
      fullbright = true
    }
  }
  
  cellSlot:setItem(cell)
end

function saveItem()
  local cfgItem = player.equippedItem("back")
  cfgItem.parameters = cfgItem.parameters or { }
  
  local inv = { } -- store items
  cfgItem.parameters.inventory = inv
  inv.cell = cellSlot:item()
  inv.pack = packSlot:item()
  inv.augment = augmentSlot:item()
  
  -- set battery stats
  cfgItem.parameters.batteryStats = nil
  if inv.cell then cfgItem.parameters.batteryStats = {
    capacity = itemutil.property(inv.cell, "/batteryStats/capacity"),
    ioRate = itemutil.property(inv.cell, "/batteryStats/ioRate"),
    energy = itemutil.property(inv.cell, "/storedEnergy") or 0,
  } end
  
  -- set epp status
  cfgItem.parameters.statusEffects = { }
  if inv.pack then -- copy EPP statuses
    util.mergeTable(cfgItem.parameters.statusEffects, inv.pack.statusEffects or root.itemConfig(inv.pack).config.statusEffects)
  end
  table.insert(cfgItem.parameters.statusEffects, "stardustlib:batterymeter") -- add battery meter after the fact
  
  -- set augment
  if inv.augment then
    local aug = itemutil.property(inv.augment, "/augment")
    if not aug then aug = { type = "back", name = "blank", displayName = "(blank)", effects = { } } end
    aug.effects = aug.effects or { }
    cfgItem.parameters.currentAugment = aug
  else
    cfgItem.parameters.currentAugment = { type = "back", name = "blank", displayName = "(blank)", effects = { } }
  end
  
  -- set light
  local lightEnabled = lightCheck.checked
  cfgItem.parameters.lightEnabled = lightEnabled
  if lightEnabled then
    table.insert(cfgItem.parameters.currentAugment.effects, "startech:augpacklight")
  end
  
  -- clear augment if it doesn't do anything, else we get instantiation failure
  if not cfgItem.parameters.currentAugment.effects[1] then cfgItem.parameters.currentAugment = nil end
  
  -- build description
  local desc = { }
  if inv.cell then
    table.insert(desc, "^darkgray;- ^gray;Cell: ^reset;")
    table.insert(desc, itemutil.property(inv.cell, "/shortdescription"))
    table.insert(desc, "\n")
  else table.insert(desc, "^darkgray;- ^gray;(no cell)\n") end
  if inv.pack then
    table.insert(desc, "^darkgray;- ^gray;EPP: ^reset;")
    table.insert(desc, itemutil.property(inv.pack, "/shortdescription"))
    table.insert(desc, "\n")
  else table.insert(desc, "^darkgray;- ^gray;(no EPP)\n") end
  if inv.augment then
    table.insert(desc, "^darkgray;- ^gray;Augment: ^reset;")
    table.insert(desc, cfgItem.parameters.currentAugment.displayName or "(unknown)")
  else table.insert(desc, "^darkgray;- ^gray;(no augment)") end
  table.insert(desc, "\n^gray;Light: ")
  table.insert(desc, cfgItem.parameters.lightEnabled and "^white;Enabled" or "^gray;Disabled")
  cfgItem.parameters.description = table.concat(desc)
  
  player.setEquippedItem("back", cfgItem)
end

function update()
  local cfgItem = player.equippedItem("back")
  if not cfgItem or cfgItem.name ~= "startech:augpack" or not cfgItem.parameters or cfgItem.parameters.syncId ~= syncId then
    return pane.dismiss()
  end
  updateCell()
end

local function startsWith(str, start)
   return str:sub(1, #start) == start
end

function cellSlot:acceptsItem(itm)
  return startsWith(itm.name, "startech:battery.t") and itm.count == 1
end
function cellSlot:onItemModified() saveItem() end

function packSlot:acceptsItem(itm)
  return itm.name ~= "startech:augpack" and root.itemType(itm.name) == "backarmor" -- reject anything that isn't a back slot
end
function packSlot:onItemModified()
  local itm = self:item()
  local aug = augmentUtil.extract(itm, true)
  if aug then
    self:setItem(itm) -- commit modified item
    if augmentSlot:item() then player.giveItem(aug) -- pop into inventory if slot full
    else augmentSlot:setItem(aug) end -- else populate it
  end
  saveItem()
end

function augmentSlot:acceptsItem(itm)
  if root.itemType(itm.name) ~= "augmentitem" or itm.count ~= 1 then return false end
  local aug = itemutil.property(itm, "/augment")
  if not aug or aug.type ~= "back" then return false end -- erroneous augment
  return true
end
function augmentSlot:onItemModified() saveItem() end

function lightCheck:onClick() saveItem() end
