-- StardustLib.ItemUtil

require "/scripts/util.lua"
require "/lib/stardust/interop.lua"

do
  itemutil = {}
  itemutil.ccache = {__c = 0}
  
  itemutil.blankItem = { name = "perfectlygenericitem", count = 0 }
  
  function itemutil.getIU() return itemutil end -- facilitate merging
  
  local function mergeCCache(iu1, iu2)
    if iu2.ccache == iu1.ccache then return nil end -- already the same
    if iu2.ccache.__c > iu1.ccache.__c then return mergeCCache(iu2, iu1) end -- assume iu1 has larger cache
    local cc, cco = iu1.ccache, iu2.ccache
    for k,v in pairs(cco) do
      if not cc[k] then
        cc[k] = v
        cc.__c = cc.__c + 1
      end
    end
    iu1.ccache = cc
    iu2.ccache = cc
  end
  
  function itemutil.mergeConfigCache(eid)
    succ, oiu = pcall(world.callScriptedEntity(eid,"itemutil.getIU"))
    if succ and oiu then mergeCCache(itemutil, oiu) end
  end
  
  function itemutil.getCachedConfig(item)
    if type(item) ~= "table" then item = { } end
    local name = item.name or "perfectlygenericitem"
    local params = item.parameters or { }
    local cc = itemutil.ccache
    if name == "sapling" then -- because they otherwise break horribly
      local cname = table.concat({ name, params.stemName or "none", params.stemHueShift or 0, params.foliageName or "none", params.foliageHueShift or 0 })
      local pc = cc[cname]
      if pc then return pc end
      pc = root.itemConfig({ name=name, parameters=params }) -- fully generic version, please
      cc[cname] = pc
      cc.__c = cc.__c + 1
      return pc
    end
    local cname = name .. (params.seed or "")
    local pc = cc[cname]
    if pc then return pc end
    pc = zpcall(root.itemConfig, { name = name, parameters = { seed = params.seed } }) -- fully generic version, please
      or itemutil.getCachedConfig({ name = "perfectlygenericitem", parameters = { } }) -- no itemexception pls
    cc[cname] = pc
    cc.__c = cc.__c + 1
    return pc
  end
  
  local function deepCompare(t1, t2)
    if t1 == t2 then return true end
    if type(t1) ~= "table" or type(t2) ~= "table" then return false end
    local v2
    for k,v1 in pairs(t1) do
      v2 = t2[k]
      if v1 ~= v2 and not deepCompare(v1, t2[k]) then return false end
    end
    for k in pairs(t2) do
      if t1[k] == nil then return false end
    end
    return true
  end
  
  function itemutil.canStack(i1, i2)
    if i1.name ~= i2.name then return false end -- if they're not the same item...
    return deepCompare(i1.parameters, i2.parameters) -- I don't think anything outside of parameters has any bearing
  end
  
  local function dive(tbl, path)
    local res = tbl
    for tk in path:gmatch("[^/]+") do
      if type(res) ~= "table" then return nil end
      res = res[tk]
    end
    return res
    --return tbl[path]
  end

  --[[function itemutil.getValue(item, path)
    item = root.itemConfig(item)
    local res = item.parameters and dive(item.parameters, path) or nil
    if res == nil then res = dive(item.config, path) end
    return res
  end]]
  
  -- returns a given property of an item, overridden where applicable
  function itemutil.property(itm, path)
    if not itm or not path then return nil end
    --return (itm.parameters and itm.parameters[prop]) or itemutil.getCachedConfig(itm).config[prop]
    local res = nil
    if itm.parameters then res = dive(itm.parameters, path) end
    if res == nil then res = dive(itemutil.getCachedConfig(itm).config, path) end
    return res
  end
  
  -- resolve path relative to item
  function itemutil.relativePath(itm, file)
    return util.absolutePath(itemutil.getCachedConfig(itm).directory, file)
  end
  
  -- normalize item descriptor
  function itemutil.normalize(itm)
    itm = itm or { }
    itm.parameters = itm.parameters or {}
    itm.count = itm.count or 0
    itm.name = itm.name or ""
    
    return itm
  end
  
  -- filter system
  do
    local function gfalse() return false end
    local filterTypes = {}
    
    filterTypes.default = function(item, config, match)
      return not not (item.parameters.shortdescription or config.config.shortdescription):lower():find(match:lower()) -- same as entering search box
    end
    filterTypes["_"] = function(item, config, match) -- _internalname
      return not not item.name:lower():find(match:lower())
    end
    filterTypes["@"] = function(item, config, match) -- @category; only internal names for now, have to figure out how to do otherwise
      return not not (item.parameters.category or config.config.category or ""):lower():find(match:lower()) -- same as entering search box
    end
    filterTypes["#"] = function(item, config, match) -- #tag (because what else); matches overall type, then item tags, then colony tags
      local mlow = match:lower()
      local type = root.itemType(item.name)
      if type == mlow or root.itemHasTag(item.name, mlow) then return true end
      if type ~= "object" then return false end -- only objects have colony tags
      for k,v in ipairs(item.parameters.colonyTags or config.config.colonyTags or {}) do
        if v == mlow then return true end
      end
    end
    
    -- specials!
    filterTypes["/"] = function(item, config, match)
      return (filterTypes[match] or gfalse)(item, config, match)
    end
    
    filterTypes.isBlock = function(item, config)
      return not not (item.parameters.materialId or config.config.materialId)
    end
    --
    
    function itemutil.matchFilter(filter, item, config)
      if not config then config = itemutil.getCachedConfig(item) end
      
      for tkn in filter:gmatch("%S+") do
        local f, m, r = filterTypes[tkn:sub(1,1)], tkn:sub(2)
        if f and m and m ~= "" then r = f(item, config, m) else r = filterTypes.default(item, config, tkn) end
        if r then return true end
      end
      return false
    end
    
  end
end
