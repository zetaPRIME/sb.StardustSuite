local modes = {
  ground = { },
  wing = { }
}
local currentMode = { }
local modeState = { }

function init()
  --playerext.message("Nanofield online.")
  status.overConsumeResource("energy", 1.0) -- debug signal
  
  setMode("ground")
end

function setMode(mode, ...)
  if currentMode == modes[mode] or not modes[mode] then return nil end
  callMode("uninit", mode)
  local prev = currentMode
  local prevState = modeState
  currentMode = modes[mode]
  modeState = { }
  callMode("init", prev, prevState, ...)
end

function callMode(f, ...)
  if currentMode[f] then currentMode[f](modeState, ...) end
end

local staticitm = "startech:nanofieldstatic"

local _prevKeys = { }
function update(p)
  if (playerext.getEquip("chest") or { }).name ~= "startech:nanofield" then
    return nil -- abort when no longer equipped
  end
  
  -- maintain other slots
  for _, slot in pairs{"head", "legs"} do
    local itm = playerext.getEquip(slot) or { name = "manipulatormodule", count = 0 }
    if itm.name ~= staticitm .. slot then
      if (playerext.getEquip(slot .. "Cosmetic") or { }).count ~= 1 then
        playerext.setEquip(slot .. "Cosmetic", itm)
      else
        playerext.giveItems(itm)
      end
      playerext.setEquip(slot, { -- clear slot afterwards so that the slot isn't empty during giveItems
        name = staticitm .. slot,
        count = 1
      })
      -- clear out static if picked up
      if (playerext.getEquip("cursor") or { }).name == staticitm .. slot then playerext.setEquip("cursor", { name = "", count = 0 }) end
    end
  end
  
  --
  p.key = p.moves p.moves = nil
  p.key.sprint = not p.key.run
  p.keyPrev = _prevKeys
  _prevKeys = p.key
  p.keyDown = { }
  for k, v in pairs(p.key) do p.keyDown[k] = v and not p.keyPrev[k] end
  callMode("update", p)
  
end

function uninit()
  callMode("uninit")
  
  -- destroy ephemera on unequip
  for _, slot in pairs{"head", "legs"} do
    local itm = playerext.getEquip(slot) or { }
    if itm.name == staticitm .. slot then
      playerext.setEquip(slot, { name = "", count = 0 }) -- clear item
    end
  end
end

-- movement modes!

local sqrt2 = math.sqrt(2)
local function vmag(vec)
  return math.sqrt(vec[1]^2 + vec[2]^2)
end

-----------------
-- ground mode --
-----------------

function modes.ground:init()
  tech.setParentState()
  mcontroller.setRotation(0)
  mcontroller.clearControls()
end

function modes.ground:update(p)
  --
  if p.keyDown["special1"] then
    setMode("wing", true)
  end
  if p.keyDown["shutup"] then
    local c = ""
    for k,v in pairs(p.key) do
      if v then c = c .. k .. ", " end
    end
    sb.logInfo("Moves: " .. c)
  end
  if p.key["sprint"] then -- sprint instead of slow walk!
    local v = 0
    if p.key["left"] then v = v - 1 end
    if p.key["right"] then v = v + 1 end
    if v ~= 0 then
      --mcontroller.controlApproachXVelocity(255 * v, 255)
      mcontroller.controlMove(v, true)
      mcontroller.controlModifiers({ speedModifier = 1.75 })
      --tech.setParentState("running")
    end
  end
  
  if mcontroller.zeroG() then setMode("wing") end
end

------------------
-- skywing mode --
------------------
function modes.wing:init(_, _, summoned)
  self.summoned = summoned
end

function modes.wing:update(p)
  local zeroG = mcontroller.zeroG()
  mcontroller.controlParameters({ gravityMultiplier = 0.0001 })
  mcontroller.controlDown()
  if self.summoned and p.keyDown.special1 then return setMode("ground") end
  
  local boost = 25
  local boostForce = 25*1.5
  
  local vx, vy = 0, 0  
  if p.key["up"] then vy = vy + 1 end
  if p.key["down"] then vy = vy - 1 end
  if p.key["left"] then vx = vx - 1 end
  if p.key["right"] then vx = vx + 1 end
  
  if vx ~= 0 and vy ~= 0 then
    vx = vx / sqrt2
    vy = vy / sqrt2
  elseif vx == 0 and vy == 0 then
    boostForce = boostForce * 1.2 -- greater braking force
  end
  
  if (vx ~= 0 or vy ~= 0) and p.key.sprint then
    boost = 55
    boostForce = boostForce * 1.5 + vmag(mcontroller.velocity()) * 2.5
  end
  
  mcontroller.controlApproachVelocity({vx*boost, vy*boost}, boostForce * 60 * p.dt)
  
  tech.setParentState("fly")
  local rot = math.max(-1.0, math.min(mcontroller.velocity()[1] / -55, 1.0))
  rot = math.sin(rot * math.pi * .45) / (.45*2)
  mcontroller.setRotation(rot * math.pi * .09)
  
  if not self.summoned and not zeroG then setMode("ground") end
  if zeroG then self.summoned = false end
end

function modes.wing:uninit()
  tech.setParentState()
  mcontroller.setRotation(0)
end




















--
