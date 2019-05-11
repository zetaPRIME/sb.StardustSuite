hud = { }

local px = 1/8 -- tile to pixel

local apGainAmt = 0
local apGainTime = 0
local apGainColor = ""

local hudLayer = "foregroundEntity+5"

function hud.update(p)
  --
  
  if apGainTime > 0 then
    local numWidth = 5
    local drw = { }
    local str = string.format("+%dA", math.floor(0.5 + apGainAmt))
    local off = (str:len() - 1) * numWidth * -0.5
    local mult = string.format("?multiply=%s?multiply=ffffff%02x", apGainColor, math.floor(0.5 + apGainTime * 255))
    --local shadow = string.format("?multiply=000000%02x", math.floor(0.5 + apGainTime * 191))
    local y = (16 + math.floor((1 - apGainTime) * 40)) * px
    for i = 1, str:len() do
      table.insert(drw, {
        position = { (off + (i - 1) * numWidth) * px, y },
        image = string.format("/aetheri/species/hud/ap.png:num%s%s", str:sub(i, i), mult),
        fullbright = true,
        renderLayer = hudLayer
      })
      --[[table.insert(drw, {
        position = { (off + (i - 1) * numWidth) * px + px, y - px },
        image = string.format("/aetheri/species/hud/ap.png:num%s%s", str:sub(i, i), shadow),
        fullbright = true,
        renderLayer = hudLayer,
        zLevel = -1
      })]]
    end
    playerext.queueDrawable(table.unpack(drw))
    apGainTime = apGainTime - p.dt / 0.75
    --
  end
  
end

function hud.gainAP(amt)
  apGainColor = color.toHex(color.fromHsl{ appearance.settings.coreHsl[1], appearance.settings.coreHsl[2], 0.85 })
  apGainAmt = amt + (apGainTime > 0 and apGainAmt or 0)
  if amt >= 10 then apGainTime = 1 end
end
