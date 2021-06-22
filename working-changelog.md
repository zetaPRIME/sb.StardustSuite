### StarTech
- Transmatter network has been **entirely rewritten** - everything should be much more stable now
  - Terminal search should be much more performant now - `/` is no longer needed to enable filter syntax and filters are compiled once instead of re-interpreting the string for each item in the list
  - The Controller and various buses have had their shading redone to better suit the style of the other parts

### Stardust Core+Lite
- Added an outline to the Quickbar button glyph to match the style of the other icons
- `input.lua` is now properly resilient against displacement (fixes issues caused by hooks)

### Stardust Core
- Modernized `network.lua` somewhat; pool objects now use method syntax (`pool:tagged()`) and are keyed by object ID instead of sequentially
- `pool:delta(old)` - compares two pools and lists IDs added and removed
- Added `tasks.lua`, a coroutine helper
- Reworked `interop.lua` slightly - added `exec()` and changed `hack()` to use it
- Added filter precompilation to `itemutil.lua` - create filter once and run on multiple items

#### metaGUI
- Theming backend improvements (`extAsset`)
- Tool tip generation is now handled by the theme, allowing for far greater visual customization
- New layout attribute: `canvasBacked`
- Fixed an issue where backspacing the beginning of a textBox would duplicate the text
