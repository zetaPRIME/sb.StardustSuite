local _init = init
function init()
  sb.logInfo("bananabana pork")
  if not player.hasQuest("stardustlib:playerext") then player.startQuest({questId="stardustlib:playerext",templateId="stardustlib:playerext",parameters={}}) end
  if _init then _init() end
end

local _displayed = displayed
function displayed()
  sb.logInfo("display")
end
