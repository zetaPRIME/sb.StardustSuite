-- common/default functions for themes

local mg = metagui
theme.common = { }
local tdef = { } -- defaults

theme.assets = { -- default assets
  frame = mg.ninePatch "frame",
  button = mg.ninePatch "button",
  
  itemSlot = mg.asset "itemSlot.png",
  itemRarity = mg.asset "itemRarity.png",
} local assets = theme.assets

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


-- copy in as defaults
for k, v in pairs(tdef) do theme[k] = v theme.common[k] = v end
