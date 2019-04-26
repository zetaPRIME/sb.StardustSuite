if not _stardustlib then
  _stardustlib = true
  
  require("/lib/stardust/playerext.lua")
  
  local _applyDamageRequest = applyDamageRequest
  function applyDamageRequest(damageRequest)
    --playerext.message("damage request recieved: " .. damageRequest.damageType)
    if damageRequest.damageType == "Damage" then
      local dr = status.stat("protectionOverride")
      if dr ~= 0.0 then
        dr = math.max(0.0, dr) -- cap to zero; this is a damage *multiplier*, so a negative value will be flat invincibility
        damageRequest.damageType = "IgnoresDef"
        damageRequest.damage = damageRequest.damage * dr
      end
    end
    return _applyDamageRequest(damageRequest)
  end
  
end
