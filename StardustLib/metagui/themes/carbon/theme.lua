-- "Carbon" theme

require "/scripts/rect.lua"

local mg = metagui

local npFrame = mg.ninePatch(asset "frame")

function theme.decorate()
  --sb.logInfo("theme decoration called")
  local m = getmetatable('')
  m.blarg = (m.blarg or 0) + 1
  --widget.addChild(frame.backingWidget, { type = "label", value = "lol wut " .. m.blarg, position = {0, 0} })
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
  local c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  local sz = frame.size
  local np = npFrame
  
  local img = np.image .. ":default"
  local rr = {0, 0, sz[1], sz[2]}
  local sr = {0, 0, np.frameSize[1], np.frameSize[2]}
  
  local invm = {np.margins[1], np.margins[4], np.margins[3], np.margins[2]}
  function npMatrix(r, m) -- calculate points
    local h = { r[1], r[1] + m[1], r[3] - m[3], r[3] }
    local v = { r[2], r[2] + m[2], r[4] - m[4], r[4] }
    local res = { { }, { }, { }, { } }
    for y=1,4 do
      for x=1,4 do
        res[y][x] = {h[x], v[y]}
      end
    end
    return res
  end
  function npRs(r, m)
    local mx = npMatrix(r, m)
    local res = { }
    for y=1,3 do
      for x=1,3 do
        local bl = mx[y][x]
        local tr = mx[y+1][x+1]
        table.insert(res, { bl[1], bl[2], tr[1], tr[2]})
      end
    end
    return res
  end
  
  local rc, sc = npRs(rr, invm), npRs(sr, invm)
  
  for i=1,9 do
    c:drawImageRect(img, sc[i], rc[i])
  end
  --[[c:drawImageRect(np.image .. ":default.br", {sz[1] - np.margins[3], 0}, 1)
  c:drawImageRect(np.image .. ":default.tl", {0, sz[2] - np.margins[4]}, 1)
  c:drawImageDrawable(np.image .. ":default.tr", {sz[1] - np.margins[3], sz[2] - np.margins[4]}, 1)]]
  
  --if m.testSvc then m.testSvc.message(nil, nil, "hook through " .. m.blarg) end
  --widget.addChild("layout", { type = "label", value = "lol wut", position = {0, 0} })
end
