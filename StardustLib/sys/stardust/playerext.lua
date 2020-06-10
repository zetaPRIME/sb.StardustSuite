-- stardustlib player extension

require "/lib/stardust/itemutil.lua"
require "/lib/stardust/power.item.lua"

getmetatable ''.clientSide = true

--[[setmetatable(_ENV, { __index = function(t,k)
  sb.logInfo("missing field "..k.." accessed")
  local f = function(...)
    local msg = "called "..k..":\n"..dump({...})
    sb.logInfo(msg)
    player.radioMessage({text=msg,messageId="scriptDbg",unique=false})
  end
  return nil -- f
end }) --]]

local function dump(o, ind)
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

local function _mightBeUsefulLater()
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

local screenMetricsUpdateTime = 0

local drawableQueue = { }
local lightQueue = { }
local particleQueue = { }

local hudSpacing = 1/8 -- single world pixel
local hudBasePos = {
  top = 16/8,
  bottom = -24/8,
}
local hudPos = { top = 0, bottom = 0 }

local lastPos = { 0, 0 }
local _update = update or function() end
function update(dt, ...)
  --[[screenMetricsUpdateTime = screenMetricsUpdateTime - 1
  if screenMetricsUpdateTime <= 0 then
    screenMetricsUpdateTime = 60
    player.interact("ScriptPane", {
      gui = { pf = { type = "panefeature", positionLocked = true, anchor = "bottomLeft" }, bg = { type = "background", fileBody = "/assetmissing.png?crop=0;0;1;1?scalenearest=1920;1080" }, c = { type = "canvas", rect = {0, 0, 1920, 1080}, captureMouseEvents = true } },
      scripts = {"/sys/stardust/playerext-screenmetrics.lua"}, scriptDelta = 1,
    })
  end--]]
  
  -- clear HUD positions
  for k in pairs(hudPos) do hudPos[k] = 0 end
  
  localAnimator.clearLightSources()
  _update(dt, ...)
  local pos = entity.position()
  local pd = vec2.sub(pos, lastPos)
  -- process localAnimator queues
  for _, e in pairs(drawableQueue) do
    if e.absolute and e.position then e.position = vec2.sub(e.position, pos) end
    --elseif e.position then e.position = vec2.sub(e.position, pd) end
    --if e.compensate then e.position = {math.floor(0.5+e.position[1]*16)/16, math.floor(0.5+e.position[2]*16)/16} end
    localAnimator.addDrawable(e, e.renderLayer)
  end drawableQueue = { }
  for _, e in pairs(lightQueue) do
    localAnimator.addLightSource(e)
  end lightQueue = { }
  for _, e in pairs(particleQueue) do
    localAnimator.spawnParticle(e)
  end particleQueue = { }
  lastPos = pos
  
  --[[ TODO: figure out a place to put this
  -- NaN protection for velocity
  local v = mcontroller.velocity()
  if v[1] ~= v[1] or v[2] ~= v[2] then
    mcontroller.setVelocity({0, 0})
  end --]]
  
  --status.setPrimaryDirectives("?replace;663b14fe=00000000;8d581cfe=00000000;c88b28fe=00000000;e7c474fe=00000000;404040fe=00000000;808080fe=00000000;6d0103fe=00000000;02da37fe=00000000;5786fffe=00000000")
end

local cfg
local internal
local svc = { }
local svci = { } -- internal utilities
local _init = init or function() end
function init(...)
  _init(...) -- run after deploy init
  for name,func in pairs(svc) do
    if type(func) == "function" then
      message.setHandler("playerext:" .. name, func)
    end
  end
  
  -- clean up remnants of playerext-as-quest
  status.clearPersistentEffects("startech:playerext")
  status.setPersistentEffects("stardustlib:playerext", {})--{"stardustlib:tableshim"})
  
  -- grab tables deployment doesn't usually have access to
  local mt = getmetatable ''
  mcontroller = mt.mcontroller
  
  -- init configuration table
  cfg = storage["stardustlib:playerconfig"] or { }
  storage["stardustlib:playerconfig"] = cfg
  internal = storage["stardustlib:_playerext_internal"] or { }
  storage["stardustlib:_playerext_internal"] = internal
  
  -- and set up techs
  svci.assertTechs()
end

local function liveMsg(msg)
  player.radioMessage({text=msg,messageId="scriptDbg",unique=false,portraitImage="/interface/chatbubbles/static.png:<frame>",portraitFrames=4,portraitSpeed=0.3,senderName="SVC"})
end

function svc.message(msg, isLocal, param)
  liveMsg(param)
end

function svc.getPlayerConfig(msg, isLocal, key, default)
  return cfg[key] or default
end

function svc.setPlayerConfig(msg, isLocal, key, value)
  cfg[key] = value
end

--[[function svc.startTabletEngine()
  local questName = "stardustlib:tablet.engine"
  if not player.hasQuest(questName) then
    player.startQuest({
      questId = questName,
      templateId = questName,
      parameters = {}
    })
  end
end]]

function svc.warp(msg, isLocal, target, animation, deploy)
  player.warp(target, animation, deploy)
end

function svc.positionWarp(msg, isLocal, targetPos)
  mcontroller.setPosition(vec2.add(targetPos, {0, 2}))
  status.removeEphemeralEffect("beamin")
  status.removeEphemeralEffect("techstun")
  status.addEphemeralEffect("beamin")
  status.addEphemeralEffect("techstun", 0.8)
end

function svc.giveItems(msg, isLocal, ...)
  local items = {...}
  for k,item in pairs(items) do
    if type(item) == "table" and item.name and item.count and item.parameters then
      player.giveItem(item)
    end
  end
end

function svc.giveItemToCursor(msg, isLocal, itm, shiftable)
  --[[
    give cursor as much as can be added to stack; give inventory the rest
  ]]
  itm = itemutil.normalize(itm) -- normalize recieved descriptor
  local cur = itemutil.normalize(player.swapSlotItem() or {name = itm.name, count = 0, parameters = itm.parameters});
  if cur.count == 0 or itemutil.canStack(cur, itm) then
    -- stack into cursor, then into inventory
    local maxStack = itemutil.property(itm, "maxStack") or 1000
    local pcount = cur.count or 0
    local ccount = pcount + itm.count
    
    local gItm = {name = itm.name, count = math.min(ccount, maxStack), parameters = itm.parameters}
    if shiftable and cur.count == 0 then -- TODO: make this work not-weirdly with already-stackables
      player.setSwapSlotItem({ name = "stardustlib:swapstub", count = 1, parameters = { mode = "shiftableGive", restore = gItm } })
    else
      player.setSwapSlotItem(gItm)
    end
    local overflow = math.max(0, ccount - maxStack)
    if overflow > 0 then
      player.giveItem({name = itm.name, count = overflow, parameters = itm.parameters})
    end
  else
    -- just give to inventory
    player.giveItem(itm)
  end
end

function svc.giveAP(msg, isLocal, ap)
  if type(ap) ~= "number" then return nil end -- malformed request
  local curAp = status.statusProperty("stardustlib:ap")
  if type(curAp) ~= "number" then curAp = 0 end -- correct
  status.setStatusProperty("stardustlib:ap", math.max(0, curAp + ap))
  if ap >= 50 then -- don't display tiny gains
    local bossAp = ap >= 10000
    localAnimator.spawnParticle {
      type = "text",
      text = string.format("^shadow;^violet;+^white;%d ^violet;AP", ap),
      size = bossAp and 0.8 or 0.6,
      fade = 0.5,
      destructionAction = "fade",
      destructionTime = 0.4,
      position = vec2.add(entity.position(), {0, 2.5}),
      offsetRegion = {0, 0, 0, 0},
      initialVelocity = bossAp and {0, 1} or {0, 8},
      finalVelocity = {0, 5},
      approach = {0, 10},
      timeToLive = bossAp and 1.5 or 0.3,
      variance = { }
    }
  end
end

function svc.openInterface(msg, isLocal, info)
  if type(info) ~= "table" then info = {config = info} end
  player.interact(info.interactionType or "ScriptPane", info.config or "/sys/stardust/tablet/tablet.ui.config")
end

function svc.openUI(msg, isLocal, info)
  if type(info) ~= "table" then info = {config = info} end
  player.interact("ScriptPane", { gui = { }, scripts = {"/metagui.lua"}, config = info.config, data = info.data })
end

local patternMatch
patternMatch = function(match, tbl)
  for k, v in pairs(match) do
    local o = tbl[k]
    if type(o) ~= type(v) then return false
    elseif type(v) == "table" then
      if not patternMatch(v, o) then return false end
    elseif tbl[k] ~= v then return false
    end
  end
  return true
end

function svc.readEquipEnergy() return {power.readEquipEnergy()} end
function svc.fillEquipEnergy(msg, isLocal, amount, testOnly, ioMult) return power.fillEquipEnergy(amount, testOnly, ioMult) end
function svc.drawEquipEnergy(msg, isLocal, amount, testOnly, ioMult) return power.drawEquipEnergy(amount, testOnly, ioMult) end
function svc.fillEquipEnergyAsync(msg, isLocal, amount, iterations) return power.fillEquipEnergy(amount, false, iterations) end

local essentialSlots = { beamaxe = true, wiretool = true, painttool = true, inspectiontool = true }
-- read/write equipped items, generally meant to be used synchronously (from techs, etc.)
function svc.getEquip(msg, isLocal, slot)
  if slot == "cursor" then return player.swapSlotItem() end
  if essentialSlots[slot] then return player.essentialItem(slot) end
  return player.equippedItem(slot)
end
function svc.setEquip(msg, isLocal, slot, item)
  if slot == "cursor" then return player.setSwapSlotItem(item) end
  if essentialSlots[slot] then return player.giveEssentialItem(slot, item) end
  return player.setEquippedItem(slot, item)
end
function svc.updateEquip(msg, isLocal, slot, match, item)
  local cur = player.equippedItem(slot)
  if not cur and not match then
  elseif type(match) ~= "table" then return false else
    if not patternMatch(match, item) then return false end
  end
  player.setEquippedItem(slot, item)
  return true
end

-- ...
function svci.assertTechs()
  internal.techRestore = internal.techRestore or { }
  if internal.techStubScript then
    -- save tech equips
    local pfx = "stardustlib:stub"
    for _, slot in pairs{"head", "body", "legs"} do
      local t = player.equippedTech(slot)
      if not t or t:sub(1, #pfx) ~= pfx then internal.techRestore[slot] = t end
    end
    
    -- force stubs
    player.makeTechAvailable("stardustlib:stubbody")
    player.enableTech("stardustlib:stubbody")
    player.equipTech("stardustlib:stubbody")
    player.makeTechAvailable("stardustlib:stublegs")
    player.enableTech("stardustlib:stublegs")
    player.equipTech("stardustlib:stublegs")
    local sa, si = "stardustlib:stub1", "stardustlib:stub2"
    if internal.techStubSwap then sa, si = si, sa end
    player.makeTechAvailable(sa)
    player.enableTech(sa)
    player.equipTech(sa)
    player.makeTechUnavailable(si)
  else
    -- hide stubs
    player.makeTechUnavailable("stardustlib:stub1")
    player.makeTechUnavailable("stardustlib:stub2")
    player.makeTechUnavailable("stardustlib:stubbody")
    player.makeTechUnavailable("stardustlib:stublegs")
    -- restore techs
    
    if internal.techRestore.head then player.equipTech(internal.techRestore.head) end
    if internal.techRestore.body then player.equipTech(internal.techRestore.body) end
    if internal.techRestore.legs then player.equipTech(internal.techRestore.legs) end
    internal.techRestore = nil
  end
end

function svc.getTechOverride(msg, isLocal) return internal.techStubScript end
function svc.overrideTech(msg, isLocal, script)
  if script then
    internal.techStubScript = script
    internal.techStubSwap = not internal.techStubSwap
  end
  svci.assertTechs()
end

function svc.restoreTech(msg, isLocal)
  internal.techStubScript = nil
  svci.assertTechs()
end

function svc.queueDrawable(msg, isLocal, ...)
  util.appendLists(drawableQueue, { ... })
end

function svc.queueLight(msg, isLocal, ...)
  util.appendLists(lightQueue, { ... })
end

function svc.queueParticle(msg, isLocal, ...)
  util.appendLists(particleQueue, { ... })
end

function svc.playAudio(msg, isLocal, sound, loops, volume)
  if type(sound) ~= "string" then return nil end
  if type(loops) ~= "number" then loops = 1 end
  if type(volume) ~= "number" then volume = 1.0 end
  localAnimator.playAudio(sound, math.floor(loops + 0.5), volume)
end

function svc.getHUDPosition(_, _, loc, size)
  if not hudBasePos[loc] then return -99999 end -- return a valid but irrelevant value for a non-thing
  local bp, hp = hudBasePos[loc], hudPos[loc] or 0
  local sign = bp >= 0 and 1 or -1
  hudPos[loc] = hp + (size + hudSpacing) * sign
  return bp + hp + size/2 * sign
end

local function deployWithoutMech()
  return status.statPositive("deployWithoutMech")
  --[[for _, slot in pairs{"chest", "back", "legs", "head"} do
    local itm = player.equippedItem(slot) or { }
    if itm.count == 1 and itemutil.property(itm, "deployWithoutMech") then return true end
  end
  return false]]
end

local _canDeploy = canDeploy
function canDeploy(...)
  if deployWithoutMech() then return true end
  return _canDeploy(...)
end

local _deploy = deploy
function deploy(...)
  if deployWithoutMech() then
    -- hmm. do something to signal deployment mode to equipment
  else pcall(_deploy, ...) end
end








--
