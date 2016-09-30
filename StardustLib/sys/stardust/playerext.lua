

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
  status.setPersistentEffects("startech:playerext", { { stat = "playerextActive", amount = 1 } })
  
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

