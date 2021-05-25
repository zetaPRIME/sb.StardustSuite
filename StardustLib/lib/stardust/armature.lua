-- Armature solver

require "/scripts/util.lua"
require "/scripts/vec2.lua"

local armature = { }
_ENV.armature = armature
local bones = { }

local boneProto = { }
do
  local boneStats = {
    parent = true,
    position = true,
    rotation = true,
    mirrored = true,
  }
  
  local function boneSet(t, k, v)
    if boneStats[k] then t.raw.solved = nil end
    t.raw[k] = v
  end
  
  armature.bones = setmetatable({ }, {
    __get = bones,
    __set = function(t, k, v)
      if type(v) ~= "table" then return end
      local b = { raw = v }
      for pk, pv in pairs(boneProto) do b[pk] = [pv] end
      setmetatable(b, {__get = v, __set = boneSet})
      bones[k] = b
    end
  })
end

function armature.newBone(k, v) armature.bones[k] = v return armature.bones[k] end

function boneProto:solve()
  if self.raw.solved then return end
  local p = armature.bones[self.raw.parent or false]
  if p then
    p:solve()
    local ps = p.raw.solved
    local s = { parent = ps.parent }
    self.raw.solved = s
    local m = ps.mirrored and -1 or 1
    s.position = vec2.rotate(vec2.mul(self.raw.position, {m, 1}), ps.rotation)
    s.rotation = ps.rotation + self.raw.rotation * m
    if ps.mirrored then s.mirrored = not self.raw.mirrored else s.mirrored = self.raw.mirrored end
  else
    self.raw.solved = {
      position = self.raw.position or {0, 0},
      rotation = self.raw.rotation or 0,
      mirrored = self.raw.mirrored,
      parent = self.raw.parent,
    }
  end
end

function armature.clearSolutions()
  for k,v in pairs(bones) v.solved = false end
end

-- TODO: child tracking and autoinvalidation
