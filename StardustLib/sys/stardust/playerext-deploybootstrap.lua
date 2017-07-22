local _init = init or function() end
function init(...)
  _init(...)
  sb.logInfo("deployment bootstrap engaged")
  --if not player.hasQuest("stardustlib:playerext") or player.hasCompletedQuest("stardustlib:playerext") then
    player.startQuest({ questId = "stardustlib:playerext", templateId = "stardustlib:playerext", parameters = {} })
  --end
end
