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
    sound = { }
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
      
      [0] = { },
      
      [1] = { },
      [2] = { },
      [3] = { },
      [4] = { },
      [5] = { }
    }
    local basePath = util.pathDirectory(ovr)
    local maxSounds = 16
    local lastSound = 0
    local soundLoops = { }
    local SoundLoop = { }
    
    local function getFile(inp)
      if type(inp) ~= "string" then return "" end
      if inp:sub(1, 1) == "/" then return inp end
      return basePath .. inp
    end
    
    function tech.setStats(data)
      if type(data) ~= "table" then data = { } end
      world.sendEntityMessage(entity.id(), "stardustlib:techoverride.setStats", data)
    end
    
    function tech.overrideMovementParams(data)
      if type(data) ~= "table" then data = { } end
      world.sendEntityMessage(entity.id(), "stardustlib:techoverride.setMovementParams", data)
    end
    
    function sound.play(file, vol, pitch, pos)
      lastSound = (lastSound % maxSounds) + 1
      local n = "eph" .. lastSound
      animator.setSoundPool(n, { getFile(file) })
      animator.setSoundVolume(n, vol or 1.0, 0)
      animator.setSoundPitch(n, pitch or 1.0, 0)
      animator.setSoundPosition(n, pos or {0, 0})
      animator.playSound(n)
    end
    
    function sound.newLoop(file, vol, pitch, pos)
      local l = { }
      for i = 1, maxSounds do
        if not soundLoops[i] then
          l.id = i
          l.n = "loop" .. i
          break
        end
      end
      if not l.n then return nil end
      soundLoops[l.id] = l
      l[valid] = true
      setmetatable(l, { __index = SoundLoop})
      l:restart(file, vol, pitch, pos)
      return l
    end
    
    function SoundLoop:restart(file, vol, pitch, pos)
      if not self[valid] then return nil end
      animator.setSoundPool(self.n, { getFile(file) })
      animator.setSoundVolume(self.n, vol or 0, 0)
      animator.setSoundPitch(self.n, math.max(pitch or 0.1, 0.1), 0)
      animator.setSoundPosition(self.n, pos or {0, 0})
      animator.playSound(self.n, -1)
    end
    
    function SoundLoop:discard()
      if not self[valid] then return nil end
      animator.stopAllSounds(self.n)
      self[valid] = false
      soundLoops[self.id] = nil
    end
    
    function SoundLoop:setVolume(vol, ramp)
      if not self[valid] then return nil end
      animator.setSoundVolume(self.n, vol or 1.0, ramp or 0)
    end
    
    function SoundLoop:setPitch(pitch, ramp)
      if not self[valid] then return nil end
      animator.setSoundPitch(self.n, math.max(pitch or 0.1, 0.1), ramp or 0)
    end
    
    function SoundLoop:setPosition(pos)
      if not self[valid] then return nil end
      animator.setSoundPosition(self.n, pos or {0, 0})
    end
    
    function Prop.new(layer)
      --sb.logInfo("prop requested on layer " .. layer)
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
      --sb.logInfo("succesfully instantiated "..p.str)
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
    
    message.setHandler("stardustlib:getPlayerAimPosition", tech.aimPosition)
    
    -- load the tech itself
    require(ovr)
    
    -- and hook in after
    require "/lib/stardust/tech/input.hook.lua" -- hook input if not already
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
