-- StardustLib.Prefabs

local prefabPath = ""
local loadedPrefabs = {}

local function loadPrefab(path)
  if loadedPrefabs[path] then return loadedPrefabs[path] end
  require("/prefabs/" .. prefabPath:gsub(".", "/"))
  local pf = __prefab
  __prefab = nil
  loadedPrefabs[path] = pf
  return pf
end

local function spawnPrefab(path, ...)
  local success, pfbase = pcall(loadPrefab, path)
  if not success then return nil end
  local pf = setmetatable({}, { __index = pfbase })
  pf:new(...)
  return pf
end

local function bcCall(t, ...)
  return spawnPrefab(prefabPath, ...)
end

local function nop() end

local breadcrumb = false -- not sure if this will really work
breadcrumb = setmetatable({}, {
  __index = function(t, k)
    prefabPath = table.concat({ prefabPath, ".", k })
    return breadcrumb
  end,
  __newindex = nop,
  __call = bcCall
})

prefabs = setmetatable({}, {
  __index = function(t, k)
    prefabPath = k
    return breadcrumb
  end,
  __newindex = nop,
  __call = bcCall
})
