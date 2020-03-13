-- common/default functions for themes

local mg = metagui
theme.common = { }
local tdef = { } -- defaults

theme.assets = { -- default assets
  frame = mg.ninePatch "frame",
  button = mg.ninePatch "button",
  scrollBar = mg.ninePatch "scrollBar",
  
  itemSlot = mg.asset "itemSlot.png",
  itemRarity = mg.asset "itemRarity.png",
} local assets = theme.assets

theme.scrollBarWidth = theme.scrollBarWidth or 6

--

function tdef.update() end -- default null

function tdef.decorate()
  widget.addChild(frame.backingWidget, { type = "canvas", position = {0, 0}, size = frame.size }, "canvas")
end

function tdef.drawFrame()
  c = widget.bindCanvas(frame.backingWidget .. ".canvas")
  c:clear() assets.frame:drawToCanvas(c)
end

function tdef.drawButton(b)
  local c = widget.bindCanvas(b.backingWidget)
  c:clear() assets.button:drawToCanvas(c, b.state or "idle")
  local acc = mg.getColor(b.color)
  if acc then assets.button:drawToCanvas(c, "accent?multiply=" .. acc) end
  c:drawText(b.caption or "", { position = vec2.add(vec2.mul(c:size(), 0.5), b.captionOffset), horizontalAnchor = "mid", verticalAnchor = "mid", wrapWidth = b.size[1] - 4 }, 8)
end

function tdef.onButtonHover(b)
  pane.playSound("/sfx/interface/hoverover_bumb.ogg", 0, 0.75)
end

function tdef.onButtonClick(b)
  pane.playSound("/sfx/interface/clickon_success.ogg", 0, 1.0)
end

function tdef.drawItemSlot(s)
  if s.deleted then return nil end
  local center = {9, 9}
  local c = widget.bindCanvas(s.backingWidget)
  c:clear() c:drawImage(assets.itemSlot .. ":" .. (s.hover and "hover" or "idle"), center, nil, nil, true)
  if s.glyph then c:drawImage(s.glyph, center, nil, nil, true) end
  local ic = root.itemConfig(s:item())
  if ic then
    local rarity = (ic.parameters.rarity or ic.config.rarity or "Common"):lower()
    c:drawImage(assets.itemRarity .. ":" .. rarity .. (s.hover and "?brightness=50" or ""), center, nil, nil, true)
  end
end

function tdef.onScroll(sa)
  local anim = sa._bar or 0
  sa._bar = 30*1.5
  if anim > 0 then return nil end
  mg.startEvent(function()
    local f = sa.subWidgets.front
    local c = widget.bindCanvas(f)
    while sa._bar > 0 do
      c:clear()
      local r = rect.withSize({0, 0}, c:size())
      r[1] = r[3] - theme.scrollBarWidth
      local viewSize = sa.size
      local contentSize = sa.children[1].size
      local scroll = sa.children[1].position
      local s, p = {0, 0}, {0, 0} for i=1,2 do
        s[i] = viewSize[i] * (viewSize[i] / contentSize[i])
        p[i] = (viewSize[i] - s[i]) * scroll[i] / (contentSize[i] - viewSize[i])
      end
      r[4] = r[4] + p[2]
      r[2] = r[4] - s[2]
      assets.scrollBar:drawToCanvas(c, string.format("default?multiply=ffffff%02x", math.ceil(math.min(sa._bar/30.0, 1.0) * 255)), r)
      sa._bar = sa._bar - 1
      coroutine.yield()
    end
    c:clear()
    sa._bar = nil
  end)
end


-- copy in as defaults
for k, v in pairs(tdef) do theme[k] = v theme.common[k] = v end
