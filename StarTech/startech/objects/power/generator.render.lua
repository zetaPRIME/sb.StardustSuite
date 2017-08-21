--

require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/interp.lua"

function init()
  self.drawPath = "/objects/tech/power/"
  self.dFlame = self.drawPath .. "generator.flame.png"
  
  dPos = vec2.add(objectAnimator.position(), {-1, 0})
  if objectAnimator.direction() == 1 then dPos[1] = dPos[1] + 5/8 end
  dPos = vec2.add(dPos, vec2.mul({3, 16 - 5}, 1/8))
  
  script.setUpdateDelta(3)
end

function update(dt)
  local lit = animationConfig.animationParameter("lit") or 0
  
  frame = frame or -1
  local lastFrame = frame
  
  if lit == 0 then
    frame = 0
  else
    frame = math.max(frame - 1, 1)
    
    -- random pop
    if math.random(30) == 1 then
      frame = math.min(
        math.random(2, 4),
        math.random(2, 4)
      )
    end
  end
  
  if frame ~= lastFrame then
    localAnimator.clearDrawables()
    
    localAnimator.addDrawable({
      image = table.concat({
        self.dFlame , ":", frame
      }),
      position = vec2.add(objectAnimator.position(), { -1, 0 }),
      fullbright = true,
      centered = false
    }, "Object-1")
  end
end
