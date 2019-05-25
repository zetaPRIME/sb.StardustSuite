--

do
  local function nf() end
  local nn = monster or npc
  --nn.say("lol internet")
  
  local contributors = { }
  
  function _aethertouched_addcontributor(id)
    if not id then return nil end
    contributors[id] = true
  end
  
  -- add anyone who does damage after an aether skill to the contributor list
  local _damage = damage or nf
  function damage(args)
    _aethertouched_addcontributor(args.sourceId)
    _damage(args)
  end
  
  -- grant experience to all (Aetheri) contributors when killed
  local _die = die or nf
  function die(...)
    -- first calculate granted AP
    local ap
    local apConfig = monster and root.assetJson("/aetheri/species/ap.config:monsters")[monster.type()]
    if apConfig then -- predefined AP gain from certain monsters
      ap = apConfig.baseAmount
    else -- calculate AP manually
      ap = world.entityHealth(entity.id())[2] * 10 -- start based on max health
      ap = ap * (1 + status.stat("protection")/100) -- bonus from armor (TODO exponential curve?)
      ap = ap * 1.1^(nn.level()-1) -- scale up in a gentle curve depending on tier
      if npc then ap = ap * 1.25 end -- bonus for taking out NPCs
    end
    ap = math.floor(0.5 + ap) -- round to int
    
    -- then loop through and send
    for p in pairs(contributors) do
      if world.entitySpecies(p) == "aetheri" then
        world.sendEntityMessage(p, "aetheri:gainAP", ap)
      end
    end
    
    -- special drops
    local pos = entity.position()
    local dropSeed = sb.staticRandomI32(entity.id(), nn.level(), pos[1], pos[2], world.time(), world.day())
    if nn.level() >= 3 then
      if sb.staticRandomI32Range(1, 50, dropSeed, "random jewel drop chance") == 1 then
        world.spawnItem({ name = "aetheri:jewel", count = 1 }, pos)
      end
      
    end
    
    _die(...)
  end
end
