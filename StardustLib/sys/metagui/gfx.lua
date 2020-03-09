metagui = metagui or { }
local mg = metagui

rectool = { }
-- left bottom right top
function rectool.topEdge(r, c) return { r[1], r[4] - c, r[3], r[4] } end
function rectool.bottomEdge(r, c) return {r[1], r[2], r[3], r[2] + c } end
function rectool.leftEdge(r, c) return { r[1], r[2], r[1] + c, r[4] } end
function rectool.rightEdge(r, c) return { r[3] - c, r[2], r[3], r[4] } end

function asset(path)
  return mg.cfg.themePath .. path
end

local nps = { }

function mg.ninePatch(path)
  if nps[path] then return nps[path] end
  local np = { } nps[path] = np
  np.image = path .. ".png"
  local d = root.assetJson(path .. ".frames")
  np.margins = d.ninePatchMargins
  np.frameSize = d.frameGrid.size
  return np
end
