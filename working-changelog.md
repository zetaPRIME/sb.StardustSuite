### StarTech
- Tinkerer's Workshop UI replaced with custom "metacrafting" system; many recipes have been added and adjusted
- Configurator system has been redesigned
- Nanofield and pulse weapon progression completely reworked: now uses a skill tree system, with AP gained from combat
- Various adjustments to Nanofield movement systems; sphere is now accessed by double-tapping down
- Elytra are now separate items that socket into the nanofield, each with their own stats and appearance
- Flight now uses a heat gauge; specific actions generate differing amounts of heat, depending on Elytra stats
- Augpack light is now local and can be toggled in configurator
- Compatibility with Frackin Universe power should be fixed
- Slightly buffed Resonite Fragment yield rate
- Telepads now use world properties for same-map transit

### StardustLib
- Workings for metacrafting and skill tree systems
- `itemutil.baseProperty()`
- Quickbar conditions: `hasFlaggedItem`, `hasTaggedItem` and `techExists` (latter being a way to check if mods are present)
- Swansong is now manually marked as a "space monster"

#### metaGUI
- Themed widget tooltips
- `widget:isMouseOver()`
- `registerUninit()`
- `stack` mode for layouts
- `visible` attribute when defining widgets
- Allow explicit width for panels
- Specify single number size for buttons and panels
- Expand mode for text boxes, including `inline` and `expand` flags as a shortcut
- Auto-cropping for image widgets to match vanilla behavior
- Fixes for `checkShift()` when holding an item with a composite icon
- Fix for multi-line labels cutting off the bottom pixel of text
