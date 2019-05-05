if not _stardustlib then
  _stardustlib = true
  
  require("/lib/stardust/playerext.lua")
  
  local err = nil

  local function resultOf(promise)
    err = nil
    if not promise:finished() then return promise end
    if not promise:succeeded() then
      err = promise:error()
      return nil
    end
    return promise:result()
  end
  
  local function queryPlayer(cmd, ...)
    return resultOf(world.sendEntityMessage((player or entity).id(), cmd, ...))
  end
  
  local _init = init
  function init() _init()
    message.setHandler("playerext:reinstateFRStatus", function()
      if self.helper and self.helper.speciesConfig and self.helper.special then
        for _, eff in pairs(self.helper.speciesConfig.special) do
  				status.addEphemeralEffect(eff, math.huge)
  			end
      end
    end)
    
    -- monkeypatch to allow hiding the matter manipulator when placing tiles
    local _spd = status.setPrimaryDirectives
    function status.setPrimaryDirectives(d)
      local dir = { status.statusProperty("stardustlib:baseDirectives", "") }
      if status.statPositive("noMatterManipulator") then
        table.insert(dir,
          "?replace;663b14fe=00000000;8d581cfe=00000000;c88b28fe=00000000;e7c474fe=00000000;404040fe=00000000;808080fe=00000000;6d0103fe=00000000;02da37fe=00000000;5786fffe=00000000" .. (d or "")
        )
      end
      table.insert(dir, d or "")
      return _spd(table.concat(dir))
    end
  end
  
  local _applyDamageRequest = applyDamageRequest
  function applyDamageRequest(damageRequest)
    --playerext.message("damage request recieved: " .. damageRequest.damageType)
    --[[if damageRequest.damageType == "Damage" then
      local dr = status.stat("protectionOverride")
      if dr ~= 0.0 then
        dr = math.max(0.0, dr) -- cap to zero; this is a damage *multiplier*, so a negative value will be flat invincibility
        damageRequest.damageType = "IgnoresDef"
        damageRequest.damage = damageRequest.damage * dr
      end
    end]]
    return _applyDamageRequest(queryPlayer("stardustlib:modifyDamageTaken", damageRequest) or damageRequest)
  end
  
end
