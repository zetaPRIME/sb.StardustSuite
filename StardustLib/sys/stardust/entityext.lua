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
    local cap = 15000
    ap = world.entityHealth(entity.id())[2] * 10 -- start based on max health
    ap = ap * (1 + 0.5 * status.stat("protection")/100) -- bonus from armor
    -- compensate for space monster stats where applicable
    -- (less of a divisor than the antiSpace multiplier because they still hit really hard)
    if status.statusProperty("stardustlib:isSpaceMonster") then ap = ap / 2.5 end
    if ap >= cap then -- exceeded cap, assume boss
      ap = cap * 1.25^(level-1) -- tier is more important than with uncapped entities
    else
      ap = ap * 1.1^(level-1) -- scale up slightly depending on tier
      if npc then ap = ap * 1.25 end -- additional bonus for taking out NPCs
    end
  end
  ap = math.floor(0.5 + ap) -- round to int
  
  -- then loop through and send
  local done = { } -- don't double-grant adjacents
  for p in pairs(hitBy) do
    world.sendEntityMessage(p, "playerext:giveAP", ap)
    local pp = world.entityPosition(p)
    if pp then
      local pl = world.playerQuery(pp, 20)
      for _, ap in pairs(pl) do -- give AP to friendly players near contributors
        if not hitBy[ap] and not done[ap] and not world.entityCanDamage(p, ap) and not world.entityCanDamage(ap, p) then
          world.sendEntityMessage(p, "playerext:giveAP", ap)
          done[ap] = true
        end
      end
    end
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
