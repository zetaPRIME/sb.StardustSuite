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
    local ap = world.entityHealth(entity.id())[2] * 10 -- start based on max health
    ap = ap * 1.1^(nn.level()-1) -- scale up in a gentle curve depending on tier
    ap = math.floor(0.5 + ap) -- round to int
    
    -- then loop through and send
    for p in pairs(contributors) do
      if world.entitySpecies(p) == "aetheri" then
        world.sendEntityMessage(p, "aetheri:gainAP", ap)
      end
    end
    _die(...)
  end
end
