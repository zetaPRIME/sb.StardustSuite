--[[local p = "/auioasudfiouasiodf/object.patch"
assets.add(p, '{"shortdescription":"uwu i\'m an object","glitchDescription":"wowie talk about a room with my view"}')

local objects = assets.byExtension("object")
for i = 1, #objects do
  assets.patch(objects[i], p)
end]]

local cfgs = assets.byExtension("config")
for k, v in pairs(cfgs) do
  assets.patch(v, "/stardustui/containerhook.patch.lua")
end
