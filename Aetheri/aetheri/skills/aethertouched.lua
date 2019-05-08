--

function init()
  world.callScriptedEntity(entity.id(), "require", "/aetheri/skills/aethertouched-hijack.lua")
  world.callScriptedEntity(entity.id(), "_aethertouched_addcontributor", effect.sourceEntity()) -- make the applier still count if oneshot
end
