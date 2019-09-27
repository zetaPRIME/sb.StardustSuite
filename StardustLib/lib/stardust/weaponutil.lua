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

local function imbue(src, imb)
  local res = util.mergeTable({ }, src or { }) -- copy
  util.appendLists(res, imb) -- and append
  if res[1] then return res end
  return nil
end

function weaponUtil.getStatusImbue()
  return querySelf("stardustlib:getStatusImbue") or { }
end

function weaponUtil.imbue(src) return imbue(src, weaponUtil.getStatusImbue()) end

function weaponUtil.encodeStatus(t) return "::" .. sb.printJson(t) end

function weaponUtil.tag(t)
  if type(t) == "string" then return weaponUtil.encodeStatus { tag = t } end
  return weaponUtil.encodeStatus(t)
end

function weaponUtil.impulse(v, raw) return weaponUtil.encodeStatus { tag = raw and "rawImpulse" or "impulse", vec = v } end
function weaponUtil.dmgTypes(t)
  if type(t) == "string" then t = { [t] = 1.0 } end
  if t[1] then -- list to array
    local tt = { }
    for _, v in pairs(t) do tt[v] = 1.0 end
    t = tt
  end
  return weaponUtil.encodeStatus { tag = "dmgTypes", t = t }
end
weaponUtil.dmgType = weaponUtil.dmgTypes -- alias
