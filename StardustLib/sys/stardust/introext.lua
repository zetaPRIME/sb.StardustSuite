require "/quests/scripts/tutorial/protectorate.lua"

local _questStart = questStart
function questStart()
  if not player.introComplete() then -- handle intro cinematic!
    local intros = config.getParameter("speciesIntroCinematics")
    player.playCinematic(intros[player.species()] or intros.default)
  end
  _questStart()
end
