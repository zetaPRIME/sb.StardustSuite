-- stardustlib player extension

require "/lib/stardust/itemutil.lua"

setmetatable(_ENV, { __index = function(t,k)
  sb.logInfo("missing field "..k.." accessed")
  local f = function(...)
    local msg = "called "..k..":\n"..dump({...})
    sb.logInfo(msg)
    player.radioMessage({text=msg,messageId="scriptDbg",unique=false})
  end
  return nil -- f
end })

function dump(o, ind)
  if not ind then ind = 2 end
  local pfx, epfx = "", ""
  for i=1,ind do pfx = pfx .. " " end
  for i=3,ind do epfx = epfx .. " " end
  if type(o) == 'table' then
    local s = '{\n'
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. pfx .. '['..k..'] = ' .. dump(v, ind+2) .. ',\n'
    end
    return s .. epfx .. '}'
  else
    return tostring(o)
  end
end

function update()
  status.setPersistentEffects("stardustlib:playerext", { { stat = "playerextActive", amount = 1 } })
  
  --player.setSwapSlotItem({name = "startech:storagenet.terminal", count = 1})
  
  --mcontroller.setRotation(math.pi*0.5)
  
  --sb.logInfo("active!!")
end

function _mightBeUsefulLater()
  local mspd = 1000
  mcontroller.clearControls()
  mcontroller.controlParameters({
    --stickyCollision = true,
    --stickyForce = 10,
    frictionEnabled = false,
    groundForce = 0,
    airForce = 0,
    gravityEnabled = false,
    airJumpProfile = {jumpControlForce = 0, jumpSpeed = 0},
    walkSpeed = mspd, runSpeed = mspd, speedLimit = mspd, flySpeed = mspd,
    
    dummy = false
  })
  mcontroller.controlDown()
  --player.giveEssentialItem("painttool", {
  --  name = "painttool",
  --  count = 1,
  --  parameters = {}
  --})
  
end

svc = {}
function init()
  for name,func in pairs(svc) do
    if type(func) == "function" then
      message.setHandler("playerext:" .. name, func)
    end
  end
end

function liveMsg(msg)
  player.radioMessage({text=msg,messageId="scriptDbg",unique=false,portraitImage="/interface/chatbubbles/static.png:<frame>",portraitFrames=4,portraitSpeed=0.3,senderName="SVC"})
end

function questStart()
  --liveMsg("Indeed!")
end

function questComplete()
  status.clearPersistentEffects("startech:playerext")
end
function questFail()
  status.clearPersistentEffects("startech:playerext")
end

function svc.message(msg, isLocal, param)
  liveMsg(param)
end

function svc.startTabletEngine()
  local questName = "stardustlib:tablet.engine"
  if not player.hasQuest(questName) then
    player.startQuest({
      questId = questName,
      templateId = questName,
      parameters = {}
    })
  end
end

function svc.giveItems(msg, isLocal, ...)
  local items = {...}
  for k,item in pairs(items) do
    if type(item) == "table" and item.name and item.count and item.parameters then
      player.giveItem(item)
    end
  end
end

function svc.giveItemToCursor(msg, isLocal, itm)
  --[[
    give cursor as much as can be added to stack; give inventory the rest
  ]]
  itemutil.normalize(itm) -- normalize recieved descriptor
  local cur = itemutil.normalize(player.swapSlotItem() or {name = itm.name, count = 0, parameters = itm.parameters});
  if cur.count == 0 or itemutil.canStack(cur, itm) then
    -- stack into cursor, then into inventory
    local maxStack = itemutil.property(itm, "maxStack") or 1000
    local pcount = cur.count or 0
    local ccount = pcount + itm.count
    
    player.setSwapSlotItem({name = itm.name, count = math.min(ccount, maxStack), parameters = itm.parameters})
    local overflow = math.max(0, ccount - maxStack)
    if overflow > 0 then
      player.giveItem({name = itm.name, count = overflow, parameters = itm.parameters})
    end
  else
    -- just give to inventory
    player.giveItem(itm)
  end
end

function svc.openInterface(msg, isLocal, info)
  if type(info) ~= "table" then info = {config = info} end
  player.interact(info.interactionType or "ScriptPane", info.config or "/sys/stardust/tablet/tablet.ui.config")
end








--
