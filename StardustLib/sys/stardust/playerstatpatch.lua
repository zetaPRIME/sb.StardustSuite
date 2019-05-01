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
