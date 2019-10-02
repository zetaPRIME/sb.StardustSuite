--
require "/scripts/util.lua"
require "/lib/stardust/color.lua"
require "/lib/stardust/itemutil.lua"
require "/lib/stardust/augmentutil.lua"

local cfgItem
local r1 = "body.r1"

do
  local slots = { }
  
  function slotL(id, ...)
    local s = slots[id]
    if s and s.onClick then s:onClick(false, ...) end
  end
  function slotR(id, ...)
    local s = slots[id]
    if s and s.onClick then s:onClick(true, ...) end
  end
  
  local function stripped(tbl)
    local nt = { }
    for k, v in pairs(tbl) do
      if type(v) ~= "function" then nt[k] = v end
    end
    return nt
  end
  
  function slotDef(tbl)
    tbl = stripped(tbl or { })
    local s = util.mergeTable({
      type = "itemslot",
      backingImage = "/interface/inventory/empty.png",
      showBackingImageWhenEmpty = true, showBackingImageWhenFull = true,
      callback = "slotL", rightClickCallback = "slotR",
    }, tbl)
    --if tbl.callback and not tbl.rightClickCallback then s.rightClickCallback = tbl.callback end
    return s
  end
  
  function addSlot(base, def)
    local id = "slot_" .. math.floor(sb.nrand() * (2^24))
    local s = { id = id }
    slots[id] = s
    s.fullId = base .. "." .. id
    widget.addChild(base, slotDef(def), id)
    
    function s:item() return widget.itemSlotItem(self.fullId) end
    function s:setItem(itm) return widget.setItemSlotItem(self.fullId, itm) end
    function s:swapWithCursor()
      local si = player.swapSlotItem()
      player.setSwapSlotItem(self:item())
      self:setItem(si)
      return si
    end
    
    return s
  end
end

local function startsWith(str, start)
   return str:sub(1, #start) == start
end


function init()
  local itm = player.swapSlotItem()
  if not itm or itm.name ~= "startech:augpack" then pane.dismiss() end
  cfgItem = itm
  player.setSwapSlotItem()
  
  -- help text
  widget.addChild("body", {
    type = "label",
    value = "Insert:\n- Pulse Cell\n- EPP or backwear\n- Augment"
  })
  
  local mainSlot = addSlot(r1)
  function mainSlot:onClick()
    if player.swapSlotItem() then return nil end -- empty hand only
    player.setSwapSlotItem(cfgItem)
    cfgItem = nil
    pane.dismiss()
  end
  
  -- spacer
  widget.addChild(r1, { type = "layout", layoutType = "basic", size = {4, 1} })
  
  local cellSlot = addSlot(r1)
  local packSlot = addSlot(r1)
  local augmentSlot = addSlot(r1)
  
  function cellSlot:onClick()
    local si = player.swapSlotItem()
    if si and (not startsWith(si.name, "startech:battery.t") or si.count > 1) then return nil end -- reject non-cells
    self:swapWithCursor()
    updateAugpack()
  end
  
  function packSlot:onClick()
    local si = player.swapSlotItem()
    if si and root.itemType(si.name) ~= "backarmor" then return nil end -- reject anything that isn't a back slot
    local itm = self:swapWithCursor()
    
    local aug = augmentUtil.extract(itm, true)
    if aug then
      self:setItem(itm) -- commit modified item
      if augmentSlot:item() then player.giveItem(aug) -- pop into inventory if slot full
      else augmentSlot:setItem(aug) end -- else populate it
    end
    
    updateAugpack()
  end
  
  function augmentSlot:onClick()
    local si = player.swapSlotItem()
    if si and root.itemType(si.name) ~= "augmentitem" then return nil end -- reject anything that isn't an augment
    if si then
      local aug = itemutil.property(si, "/augment")
      if not aug or aug.type ~= "back" then return nil end -- erroneous augment
    end
    self:swapWithCursor()
    updateAugpack()
  end
  
  --
  
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
  
  do -- populate item slots
    local inv = cfgItem.parameters.inventory or { }
    if inv.cell then -- update cell properties
      local fp = cfgItem.parameters.batteryStats and cfgItem.parameters.batteryStats.energy or 0
      inv.cell.parameters.storedEnergy = fp
      local capacity = itemutil.property(inv.cell, "/batteryStats/capacity")
      -- set description
      inv.cell.parameters.description = string.format("%s\n^green;%d^darkgreen;/^green;%d^darkgreen;FP^reset;",
        itemutil.property(inv.cell, "/baseDescription"), math.floor(fp), math.floor(capacity)
      )
      -- build icon (TODO: do this stuff in a builder instead)
      batLevel = fp / capacity
      inv.cell.parameters.inventoryIcon = {
        { image = itemutil.property(inv.cell, "/iconBaseImage") or "battery.frame.png" },
        {
          image = table.concat({
            "battery.meter.png?addmask=/startech/objects/power/battery.meter.png", ";0;",
            10 - math.floor(batLevel * 10),
            "?multiply=", color.toHex(color.fromHsl{math.max(0, batLevel*1.25 - 0.25) * 1/3, 1, 0.5, 1})
          }),
          fullbright = true
        }
      }
    end
    cellSlot:setItem(inv.cell)
    packSlot:setItem(inv.pack)
    augmentSlot:setItem(inv.augment)
  end
  
  --
  
  -- update item in its slot
  function updateAugpack()
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
    local lightEnabled = true
    cfgItem.parameters.lightEnabled = lightEnabled
    if lightEnabled then
      table.insert(cfgItem.parameters.currentAugment.effects, "lightaugment2")
    end
    
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
    
    mainSlot:setItem(cfgItem)
  end updateAugpack()
end

function uninit()
  if cfgItem then player.giveItem(cfgItem) end
end

function update()
  
end
