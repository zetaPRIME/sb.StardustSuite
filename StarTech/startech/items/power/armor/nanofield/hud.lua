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

function hud.update(p)
  --
  if showTime > 0 then
    local alpha = math.min(1.0, showTime)
    showTime = showTime - p.dt
    
    local cur, max = table.unpack(playerext.readEquipEnergy())
    local percent = math.ceil(100 * cur / max)
    
    local numWidth = 5
    local drw = { }
    local str = string.format("%d%%", percent)
    --local str = string.format("%d", safeFloor(0.5 + status.resourcePercentage("aetheri:mana") * 100))
    local off = ((str:len() - 1) * numWidth - 4) * -0.5
    local mult = color.alphaDirective(alpha)
    local y = -28 * px
    for i = 1, str:len() do
      table.insert(drw, {
        position = { (off + (i - 1) * numWidth) * px, y },
        image = string.format("/startech/items/power/armor/nanofield/hud.png:num%s%s", str:sub(i, i), mult),
        fullbright = true,
        renderLayer = hudLayer
      })
    end
    playerext.queueDrawable(table.unpack(drw))
  end
  --
end

local function show() showTime = 2 end
message.setHandler("stardustlib:onDrawEquipEnergy", show)
message.setHandler("stardustlib:onFillEquipEnergy", show)
