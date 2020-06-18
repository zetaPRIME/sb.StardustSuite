--
require "/scripts/util.lua"

local function nf() end -- null function
local nn = monster or npc

local hitBy = { }

local function addHitBy(id)
  if not id then return nil end
  if world.entityType(id) == "player" then hitBy[id] = true end
end

-- keep track of all players who contribute to a kill
local _damage = damage or nf
function damage(args)
  addHitBy(args.sourceId)
  -- send a notification for leech purposes
  world.sendEntityMessage(args.sourceId, "stardustlib:damagedEntity", entity.id(), args.sourceDamage, args.damage, args.sourceKind)
  _damage(args)
end

-- grant experience to all (Aetheri) contributors when killed
local _die = die or nf
function die(...)
  local level = nn.level()
  -- first calculate granted AP
  local ap = config.getParameter("stardustlib:givesAP", nil)
  local apConfig = monster and root.assetJson("/sys/stardust/ap.config:monsters")[monster.type()]
  if ap then -- configured in the entity itself
    -- already there
  elseif apConfig then -- predefined AP gain from certain monsters
    ap = apConfig.baseAmount
  else -- calculate AP manually
    ap = world.entityHealth(entity.id())[2] * 10 -- start based on max health
    ap = ap * (1 + 0.5 * status.stat("protection")/100) -- bonus from armor
    ap = ap * 1.1^(level-1) -- scale up slightly depending on tier
    if npc then ap = ap * 1.25 end -- additional bonus for taking out NPCs
  end
  ap = math.floor(0.5 + ap) -- round to int
  
  -- then loop through and send
  for p in pairs(hitBy) do
    world.sendEntityMessage(p, "playerext:giveAP", ap)
  end
  
  --[[ special drops
  local pos = entity.position()
  local dropSeed = sb.staticRandomI32(entity.id(), nn.level(), pos[1], pos[2], world.time(), world.day())
  if level >= 2 then
    if sb.staticRandomI32Range(1, 50, dropSeed, "random jewel drop chance") == 1 then
      world.spawnItem({ name = "aetheri:jewel", count = 1, parameters = { level = level, seed = sb.staticRandomI32(dropSeed, "LOST LOGIA: JEWEL SEED") } }, pos)
    end
  end--]]
  
  _die(...)
end
