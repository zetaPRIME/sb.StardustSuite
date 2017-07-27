require "/lib/stardust/itemutil.lua"

_ENV = __layout -- adopt local environment

numSlots = 5

function init()
  ui.addLabel({ position = {22, startY - 5}, wrapWidth = 108 }, "Place ^green;EPP modules^reset; or ^green;augments^reset; in these slots to add their effects to your augpack.\n\n^darkgray;(This includes augments already socketed into an EPP)^reset;")
  
  local item = ui.mainSlotItem()
  local augs = item.parameters.insertedItems or {}
  
  for i = 1, numSlots do
    local si = "s" .. i
    ui.addItemSlot({2, startY - (3 + i*20)}, nil, slotCallback)
    ui.slotSetItem(i, augs[si])
  end
end

function slotCallback(item)
  if not item or not item.count or item.count <= 0 then return updateItem end
  local cfg = itemutil.getCachedConfig(item).config
  if cfg.augment and cfg.augment.type == "back" then return updateItem end
  if cfg.category == "enviroProtectionPack" then return updateItem end
end

function updateItem()
  local item = ui.mainSlotItem()
  local augs = item.parameters.insertedItems or {}
  
  local desc = ""
  local numAugs = 0
  
  local astatus = {}
  
  local augfx = {}
  
  for i = 1, numSlots do
    local si = "s" .. i
    augs[si] = ui.slotItem(i)
    if augs[si] then
      numAugs = numAugs + 1
      local par = augs[si].parameters
      local cfg = itemutil.getCachedConfig(augs[si]).config
      desc = string.format("%s- %s", desc, augs[si].parameters.shortdescription or cfg.shortdescription)
      
      if cfg.augment and cfg.augment.type == "back" then
        for k, v in pairs(cfg.augment.effects) do
          augfx[#augfx+1] = v
        end
      elseif cfg.category == "enviroProtectionPack" then
        for k, v in pairs(cfg.statusEffects or {}) do
          if type(v) == "table" then
            astatus[v.stat] = (v.amount or 1) + (astatus[v.stat] or 0)
          else
            augfx[#augfx+1] = v -- guess this is the only actual way to have effects that don't have an amount attached along with ones that do!
          end
        end
        if par.currentAugment then
          for k, v in pairs(par.currentAugment.effects) do
            augfx[#augfx+1] = v
          end
          desc = desc .. "+"
        end
      end
      
      if augs[si].count > 1 then desc = string.format("%s (%i)", desc, augs[si].count) end
    else
      desc = string.format("%s- ^darkgray;(no item)^reset;", desc)
    end
    desc = desc .. "\n"
  end
  
  local fstatus = {}
  for k, v in pairs(astatus) do fstatus[#fstatus+1] = {stat = k, amount = v} end
  if #fstatus == 0 then fstatus = nil end
  
  item.parameters.insertedItems = augs -- make sure it's actually in the item
  if numAugs > 0 then
    item.parameters.description = desc
  else
    item.parameters.description = nil
  end
  item.parameters.statusEffects = fstatus
  
  if #augfx == 0 then
    item.parameters.currentAugment = nil
  else
    item.parameters.currentAugment = {
      type = "back",
      name = "custom",
      displayName = "(multiple slots)",
      effects = augfx
    }
  end
  
  ui.mainSlotSetItem(item)
end

--
