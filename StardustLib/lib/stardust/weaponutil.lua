weaponUtil = { }
weaponutil = weaponUtil

local function resultOf(promise)
  err = nil
  if not promise:finished() then return promise end
  if not promise:succeeded() then
    err = promise:error()
    return nil
  end
  return promise:result()
end

local function querySelf(cmd, ...)
  return resultOf(world.sendEntityMessage(entity.id(), cmd, ...))
end

function weaponUtil.getStatusImbue()
  return querySelf("stardustlib:getStatusImbue") or { }
end
