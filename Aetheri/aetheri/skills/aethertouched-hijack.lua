--

do
  local npc = monster or npc
  --npc.say("lol internet")
  
  local _die = die or function() end
  function die(...)
    for _, p in pairs(world.playerQuery(entity.position(), 25*2)) do
      if world.entitySpecies(p) == "aetheri" then
        world.sendEntityMessage(p, "playerext:message", string.format("A(n) %s died; %f experience gained", world.entityTypeName(entity.id()), world.entityHealth(entity.id())[2]))
      end
    end
    _die(...)
  end
end
