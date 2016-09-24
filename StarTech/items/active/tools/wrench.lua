require "/scripts/util.lua"
require "/scripts/vec2.lua"

require "/lib/stardust/sync.lua"

local _init = init
function init()
  _init()
  --self.previousMoves = {}
  self.previousFireMode = nil
end

local _uninit = uninit
function uninit()
  _uninit()
  --cancel()
end

local _update = update
function update(dt, fireMode, shiftHeld, moves)
  sync.runQueue()
  
  _update(dt, fireMode, shiftHeld, moves)
  if fireMode == "alt" and self.previousFireMode ~= "alt" then
    if self.projectileId then
      cancel()
    elseif status.stat("activeMovementAbilities") < 1 then
      xfire(moves, shiftHeld)
    end
  end
  self.previousFireMode = fireMode
end

function xfire(moves, shiftHeld)
  local aim = activeItem.ownerAimPosition()
  aim[1] = math.floor(aim[1])
  aim[2] = math.floor(aim[2])
  --local el = world.objectQuery(aim, 0)--0.01)
  local target = world.objectAt(aim)
  if target then
    --world.callScriptedEntity(el[1], "require", "/items/active/tools/wrtest.lua")
    --world.containerOpen(el[1])
    local pp = world.entityPosition(activeItem.ownerEntityId())
    pp = vec2.add(pp, {0, -.5})
    local dist = world.magnitude(vec2.add(aim, {.5,-.5}), pp)
    sb.logInfo("dist " .. dist .. " aimY " .. aim[2] .. " playerY " .. pp[2])
    if dist > 5.5 then return nil end -- roughly match interface range
    sync.target(target).poll("wrenchInteract", onInteractComplete, activeItem.ownerEntityId(), shiftHeld)
  end
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function onInteractComplete(rpc)
  local response = rpc:result() or {}
  sb.logInfo("response")
  if response.interact then
    sb.logInfo("interact response")
    activeItem.interact(response.interact.type, response.interact.id, response.interact.customConfig or root.assetJson(response.interact.config))
  end
end

if false then -- testing probe
  setmetatable(_ENV, { __index = function(t,k)
    sb.logInfo("missing field "..k.." accessed")
    local f = function(...)
      sb.logInfo("called")
    end
    return nil -- f
  end })
end
