--

do
  local npc = monster or npc
  --npc.say("lol internet")
  
  local contributors = { }
  
  function _aethertouched_addcontributor(id)
    if not id then return nil end
    contributors[id] = true
  end
  
  -- add anyone who does damage after an aether skill to the contributor list
  local _damage = damage or function() end
  function damage(args)
    _aethertouched_addcontributor(args.sourceId)
    _damage(args)
  end
  
  -- grant experience to all (Aetheri) contributors when killed
  local _die = die or function() end
  function die(...)
    -- first calculate granted xp
    local experience = math.floor(0.5 + world.entityHealth(entity.id())[2] * 10)
    
    -- then loop through and send
    for p in pairs(contributors) do
      if world.entitySpecies(p) == "aetheri" then
        world.sendEntityMessage(p, "playerext:message", string.format("Killed %s; %d experience gained", world.entityTypeName(entity.id()), experience))
      end
    end
    _die(...)
  end
end
