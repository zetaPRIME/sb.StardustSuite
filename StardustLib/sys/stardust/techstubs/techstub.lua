-- Equipment tech stub
require("/lib/stardust/playerext.lua")

function init()
  init = function() end
  if config.getParameter("active") then
    local ovr = playerext.getTechOverride()
    if not ovr then return nil end -- abort activation if no override
    uninit = nil
    
    -- load in libraries for guest
    require("/scripts/util.lua")
    
    -- library time!
    local propManager = { }
    Prop = { }
    local valid = { } -- keyed
    
    propManager.propsPerLayer = 8
    propManager.map = {
      [-1] = { },
      [-2] = { },
      [-3] = { },
      [-4] = { },
      [-5] = { },
      
      [1] = { },
      [2] = { },
      [3] = { },
      [4] = { },
      [5] = { }
    }
    local basePath = util.pathDirectory(ovr)
    
    local function getFile(inp)
      if type(inp) ~= "string" then return "" end
      if inp[1] == "/" then return inp end
      return basePath .. inp
    end
    
    function Prop.new(layer)
      sb.logInfo("prop requested on layer " .. layer)
      if not layer or not propManager.map[layer] then return nil end
      local p = { }
      for i = 1, propManager.propsPerLayer do
        if not propManager.map[layer][i] then
          p.layer = layer
          p.id = i
          break
        end
      end
      if not p.id then return nil end
      
      propManager.map[p.layer][p.id] = p
      p.str = "layer" .. p.layer .. "prop" .. p.id
      sb.logInfo("succesfully instantiated "..p.str)
      p[valid] = true
      setmetatable(p, {__index = Prop})
      p:reset()
      return p
    end
    
    function Prop:reset()
      if not self[valid] then return nil end
      animator.setPartTag(self.str, "partImage", "")
      animator.setPartTag(self.str, "animFrame", "")
      animator.setPartTag(self.str, "directives", "")
      local sf = self.str .. "f"
      animator.setPartTag(sf, "partImage", "")
      animator.setPartTag(sf, "animFrame", "")
      animator.setPartTag(sf, "directives", "")
      self:resetTransform()
    end
    
    function Prop:discard()
      if not self[valid] then return nil end
      self:reset()
      self[valid] = nil
      propManager.map[self.layer][self.id] = nil
    end
    
    function Prop:resetTransform()
      if not self[valid] then return nil end
      animator.resetTransformationGroup(self.str)
    end
    
    function Prop:translate(vec)
      if not self[valid] then return nil end
      animator.translateTransformationGroup(self.str, vec)
    end
    function Prop:scale(vec, around)
      if not self[valid] then return nil end
      animator.scaleTransformationGroup(self.str, vec, around)
    end
    function Prop:rotate(rot, around)
      if not self[valid] then return nil end
      animator.rotateTransformationGroup(self.str, rot, around)
    end
    
    function Prop:setImage(img, fb)
      if not self[valid] then return nil end
      animator.setPartTag(self.str, "partImage", getFile(img))
      animator.setPartTag(self.str, "animFrame", "")
      animator.setPartTag(self.str, "directives", "")
      local sf = self.str .. "f"
      animator.setPartTag(sf, "partImage", getFile(fb))
      animator.setPartTag(sf, "animFrame", "")
      animator.setPartTag(sf, "directives", "")
    end
    
    function Prop:setFrame(f)
      if not self[valid] then return nil end
      f = f or ""
      -- TODO: allow setting altered frame for fullbright
      animator.setPartTag(self.str, "animFrame", f)
      animator.setPartTag(self.str .. "f", "animFrame", f)
    end
    
    function Prop:setDirectives(d, fd)
      if not self[valid] then return nil end
      d = d or ""
      local fd = fd or ""
      animator.setPartTag(self.str, "directives", d)
      animator.setPartTag(self.str .. "f", "directives", fd)
    end
    
    -- load the tech itself
    require(ovr)
    
    -- and hook in after
    local _uninit = uninit or function() end
    uninit = function()
      _uninit()
      -- reassert until released
      if playerext.getTechOverride() then playerext.overrideTech() end
    end
    init()
  end
end

function uninit()
  -- reassert until released
  if playerext.getTechOverride() then playerext.overrideTech() end
end
