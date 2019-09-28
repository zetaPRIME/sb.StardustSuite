require "/lib/stardust/playerext.lua"
require "/lib/stardust/color.lua"

hud = { }

local px = 1/8 -- tile to pixel
local hudLayer = "foregroundEntity+5"

local function safeFloor(num)
  if (type(num) ~= "number") or (num ~= num) or (num + 1 == num) then return 0 end -- starbound has faulty NaN behavior??
  return math.floor(num)
end

local showTime = 0
function init()
  script.setUpdateDelta(1)
end

local charWidth = {
  default = 4,
  B = 6,
  ["%"] = 7,
}
local charColor = {
  B = "?multiply=9771e4"
}

local _i = true
function update(p)
  if _i then _i = false
    if world.entityType(entity.id()) ~= "player" then update = nil script.setUpdateDelta(0) return nil end
    
    local function show() showTime = 2 end show()
    message.setHandler("stardustlib:onDrawEquipEnergy", show)
    message.setHandler("stardustlib:onFillEquipEnergy", show)
  end
  --
  if showTime > 0 then
    local alpha = math.min(1.0, showTime)
    showTime = showTime - script.updateDt()
    
    local cur, max = table.unpack(playerext.readEquipEnergy())
    if not max or max <= 0 then showTime = 0 return nil end
    local percent = math.ceil(100 * cur / max)
    
    local defColor = percent > 15 and "" or percent > 5 and "?multiply=ff7f7f" or "?multiply=ff0000"
    
    local numWidth = 5
    local drw = { }
    local str = string.format("B%d%%", percent)
    local width = str:len() - 1
    for i = 1, str:len() do
      width = width + (charWidth[str:sub(i, i)] or charWidth.default)
    end
    
    local off = -width/2--((str:len() - 1) * numWidth - 4) * -0.5
    local mult = color.alphaDirective(alpha)
    local x, y = 0, playerext.getHUDPosition("bottom", 1)
    for i = 1, str:len() do
      local ch = str:sub(i, i)
      local color = charColor[ch] or defColor
      table.insert(drw, {
        position = { (4 + off + x) * px, y },
        image = string.format("/sys/stardust/hud/hud1.png:%s%s%s", ch, color, mult),
        fullbright = true,
        renderLayer = hudLayer
      })
      x = x + (charWidth[ch] or charWidth.default) + 1
    end
    playerext.queueDrawable(table.unpack(drw))
  end
  --
end
