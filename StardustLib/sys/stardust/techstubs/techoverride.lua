require("/lib/stardust/playerext.lua")
require("/lib/stardust/itemutil.lua")

local scr -- variable containing the script path to take
local modGroup -- stat modifier group!
--local movementParams = { }

local function set()
  if scr then return nil end
  for _, slot in pairs{"head", "legs", "back", "chest"} do
    local itm = playerext.getEquip(slot) or { }
    if itm.count then
      scr = itemutil.property(itm, "techScript") or scr
    end
  end
  if scr then playerext.overrideTech(scr) end
end

function init()
  --set()
  script.setUpdateDelta(1)
end

function update(dt)
  modGroup = effect.addStatModifierGroup({ })
  message.setHandler("stardustlib:techoverride.setStats", function(msg, isLocal, data)
    effect.setStatModifierGroup(modGroup, data or { })
  end)
  message.setHandler("stardustlib:techoverride.setMovementParams", function(msg, isLocal, data)
    movementParams = data or { }
  end)
  script.setUpdateDelta(0)
  set()
  update = function(dt)
    --mcontroller.controlParameters(movementParams)
    --status.setPrimaryDirectives("?setcolor=BADA55")
    --status.setPrimaryDirectives("?replace;663b14fe=00000000;8d581cfe=00000000;c88b28fe=00000000;e7c474fe=00000000;404040fe=00000000;808080fe=00000000;6d0103fe=00000000;02da37fe=00000000;5786fffe=00000000")
  end update(dt)
end

function uninit()
  if playerext.getTechOverride() == scr then playerext.restoreTech() end
end
