-- Chroma theme

require "/lib/stardust/color.lua"

local mg = metagui
local assets = theme.assets

for _, ast in pairs {
  assets.frame, assets.panel,
  assets.textBox,
  assets.tabPanel, assets.tab,
  assets.checkBox, assets.radioButton,
  assets.itemSlot,
} do ast.useThemeDirectives = "primaryDirectives" end
theme.primaryDirectives = "?multiply=" .. mg.getColor "accent" .. "?brightness=75?multiply=ffffffbf"
