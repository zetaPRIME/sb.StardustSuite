require "/lib/stardust/sync.lua"

iostate = {
  i = {
    key = {},
    mouse = {},
    mousePos = {0, 0} -- x,y
  },
  o = {
    draw = {},
    soundQueue = {}
  },
  next = true
}

dFunc = {}

fontCache = {}
function dFunc.font(fontImg, fsrc, color, ...)
  local lst = {...}
  if not fontCache[fontImg] then fontCache[fontImg] = {} end
  local fc = fontCache[fontImg]
  local function cfc(chr)
    if fc[chr] then return fc[chr] end
    fc[chr] = fontImg .. chr
    return fc[chr]
  end
  for k,v in ipairs(lst) do
    canvas:drawImageRect(cfc(v[1]), fsrc, v[2], v[3] or color)
  end
end

function init()
  canvas = widget.bindCanvas("scriptCanvas")
  widget.focus("scriptCanvas")
  --canvasDraw 10char
  --for k,v in pairs(canvas) do
  --  if k:sub(1, 4) == "draw" then dFunc[k:sub(5, 5):lower() .. k:sub(6)] = v end
  --end
  dFunc.image = function(...) canvas:drawImage(...) end
  dFunc.imageDrawable = function(...) canvas:drawImageDrawable(...) end
  dFunc.imageRect = function(...) canvas:drawImageRect(...) end
  dFunc.tiledImage = function(...) canvas:drawTiledImage(...) end
  dFunc.line = function(...) canvas:drawLine(...) end
  dFunc.rect = function(...) canvas:drawRect(...) end
  dFunc.poly = function(...) canvas:drawPoly(...) end
  dFunc.triangles = function(...) canvas:drawTriangles(...) end
  
  -- ... let's disabuse the json serializer of the idea that these might be json arrays
  iostate.i.key["."] = false
  iostate.i.mouse["."] = false
  
  --sb.logInfo("player table " .. (player and "" or "not ") .. "found")
end

function displayed()
  -- init engine if not present
  sync.msg("playerext:startTabletEngine")
  -- and notify
  sync.msg("sdltablet:uiAttach")
end

function uninit()
  sync.msg("sdltablet:uiDetach")
end

function update()
  iostate.i.mousePos = canvas:mousePosition()
  if iostate.next then
    iostate.next = false
    sync.poll("sdltablet:uiUpdate", onReceiveResponse, iostate.i)
  end
  sync.runQueue() -- apparently it's synchronous in this case!
  drawFromQueue()
  -- TODO: SOUND
  
  --console.canvasDrawRect({0, 0, 1024, 1024}, {0, 0, 0}) -- blank
  --console.canvasDrawRect({0, 16, 160, 256}, {255, 0, 0})
  --console.canvasDrawText(info or "Hello.", {position = {2, 12}}, 8, {255, 255, 255, 255})
end

function onReceiveResponse(rpc)
  iostate.next = true
  if not rpc:succeeded() then
    -- debug stuff here
    return nil
  end
  local res = rpc:result()
  iostate.o.draw = res.draw or {}
  iostate.o.soundQueue = res.soundQueue or {}
  
  --
end

function drawFromQueue()
  canvas:clear()
  canvas:drawRect({0, 0, 1024, 1024}, {0, 0, 0}) -- blankslate
  for _,q in ipairs(iostate.o.draw) do
    --sb.logInfo(dump(q))
    dFunc[q[1]](table.unpack(q, 2))
  end
end

function canvasKeyEvent(key, keyDown)
  iostate.i.key[key] = keyDown or nil -- clear if false
end

function canvasClickEvent(position, key, keyDown)
  iostate.i.mouse[key] = keyDown or nil -- clear if false
end

function scroll(...)
  sb.logInfo("scroll event")
end

setmetatable(_ENV, { __index = function(t,k)
  info = "missing field "..k.." accessed"
  local f = function(...)
    local msg = "called "..k..":\n"..dump({...})
    sb.logInfo(msg)
    player.radioMessage({text=msg,messageId="scriptDbg",unique=false})
  end
  return nil -- f
end })

function dump(o, ind)
  if not ind then ind = 2 end
  local pfx, epfx = "", ""
  for i=1,ind do pfx = pfx .. " " end
  for i=3,ind do epfx = epfx .. " " end
  if type(o) == 'table' then
    local s = '{\n'
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. pfx .. '['..k..'] = ' .. dump(v, ind+2) .. ',\n'
    end
    return s .. epfx .. '}'
  else
    return tostring(o)
  end
end
