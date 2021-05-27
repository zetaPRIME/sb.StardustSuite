require "/scripts/util.lua"
require "/scripts/vec2.lua"

function init()
  entityId = animationConfig.animationParameter("entityId")
end

function update(dt)
  local pos = activeItemAnimation.ownerPosition()
  
  -- fetch and sort drawables
  local dl = { }
  for _, d in pairs(animationConfig.animationParameter("drawableList") or { }) do table.insert(dl, d) end
  table.sort(dl, function(a, b) return (a.z or 0) < (b.z or 0) end)
  
  -- then draw
  localAnimator.clearDrawables()
  for _, d in pairs(dl) do
    localAnimator.addDrawable({
      image = d.image,
      position = vec2.add(d.position, pos),
      rotation = d.rotation,
      centered = true,
      mirrored = d.mirrored,
    }, d.layer or "Player")
  end
end

-- TODO: sounds
