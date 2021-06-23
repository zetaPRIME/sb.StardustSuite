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
    return root.itemDescriptorsMatch(i1, i2, true) -- just use the native function; potentially much faster than lua iteration
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
    local res = nil
    if itm.parameters then res = dive(itm.parameters, path) end
    if res == nil then res = dive(itemutil.getCachedConfig(itm).config, path) end
    return res
  end
  -- same, but only the base config
  function itemutil.baseProperty(itm, path)
    if not itm or not path then return nil end
    return dive(itemutil.getCachedConfig(itm).config, path)
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
    local filterDef = { }
    
    function filterDef.default(item, config, match)
      return not not (item.parameters.shortdescription or config.config.shortdescription):lower():find(match:lower(), 1, true) -- same as entering search box
    end
    filterDef["_"] = function(item, config, match) -- _internalname
      return not not item.name:lower():find(match:lower(), 1, true)
    end
    filterDef["@"] = function(item, config, match) -- @category; only internal names for now, have to figure out how to do otherwise
      return not not (item.parameters.category or config.config.category or ""):lower():find(match:lower(), 1, true) -- same as entering search box
    end
    filterDef["#"] = function(item, config, match) -- #tag (because what else); matches overall type, then item tags, then colony tags
      local mlow = match:lower()
      local type = root.itemType(item.name)
      if type == mlow or root.itemHasTag(item.name, mlow) then return true end
      if type ~= "object" then return false end -- only objects have colony tags
      for k,v in ipairs(item.parameters.colonyTags or config.config.colonyTags or {}) do
        if v == mlow then return true end
      end
    end
    
    -- specials! essentially slash-commands --
    
    function filterDef.isBlock(item, config)
      return not not (item.parameters.materialId or config.config.materialId)
    end
    
    function filterDef.type(item, config, arg)
      return root.itemType(item.name) == arg
    end
    function filterDef.typesub(item, config, arg)
      return not not root.itemType(item.name):find(arg, 1, true)
    end
    
    filterDef.id = filterDef["_"] -- longform alias
    
    -- -- --
    
    local filterProto = { }
    filterProto.__index = filterProto -- use as own metatable
    
    function filterProto:__call(item, cfg)
      if not cfg then cfg = itemutil.getCachedConfig(item) end
      
      if self.any then
        for k,f in pairs(self.steps) do
          if f(item, cfg) then return true end
        end
        return false
      end
      
      for k,f in pairs(self.steps) do
        if not f(item, cfg) then return false end
      end
      return true
    end
    
    function itemutil.filter(fs)
      local ft = setmetatable({ steps = { } }, filterProto)
      
      for tk in fs:gmatch("%S+") do
        local ch, m, step = tk:sub(1,1), tk:sub(2)
        
        if ch == "%" and not ft[m] then
          ft[m] = true
        elseif ch == "/" then
          local p
          local sep = m:find("=", 1, true)
          if sep then
            p = m:sub(sep+1)
            m = m:sub(1,sep-1)
          end
          local f = filterDef[m]
          if f then step = function(i, c) return f(i, c, p) end end
        else
          local f = filterDef[ch]
          if f and m and m ~= "" then
            step = function(i, c) return f(i, c, m) end
          else
            f = filterDef.default
            step = function(i, c) return f(i, c, tk) end
          end
        end
        
        if step then table.insert(ft.steps, step) end
      end
      
      return ft
    end
    
    function itemutil.matchFilter(filter, item, config)
      return itemutil.filter(filter)(item, config)
    end
    
  end
end
