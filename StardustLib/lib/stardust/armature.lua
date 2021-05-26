-- Armature solver

require "/scripts/util.lua"
require "/scripts/vec2.lua"

local armature = { }
_ENV.armature = armature
armature.hooks = { }
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
    if boneStats[k] then
      if k == "parent" then
        local op = bones[t.raw.parent or false]
        if op then op.children[t] = nil end
        local np = bones[v or false]
        if np then np.children[t] = true end
      end
      t:clearSolution()
    end
    t.raw[k] = v
  end
  
  armature.bones = setmetatable({ }, {
    __get = bones,
    __set = function(t, k, v)
      if type(v) ~= "table" then return end
      local b = { raw = v, children = { } }
      for pk, pv in pairs(boneProto) do b[pk] = [pv] end
      setmetatable(b, {__get = v, __set = boneSet})
      bones[k] = b
      local np = bones[v.parent or false]
      if np then np.children[b] = true end
    end
  })
end

function armature.newBone(k, v) armature.bones[k] = v return bones[k] end

function boneProto:solve()
  if self.raw.solved then return end
  local p = bones[self.raw.parent or false]
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

function boneProto:clearSolution(sub)
  if not self.raw.solved then return end
  self.raw.solved = nil
  for c in pairs(self.children) do
    c:clearSolution()
  end
  local h = armature.hooks.onClearSolution
  if h then h(self) end
end

function armature.clearSolutions()
  for k,v in pairs(bones) v.raw.solved = false end
end
