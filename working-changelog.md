### StarTech
- Transmatter network has been **entirely rewritten** - everything should be much more stable now
  - Terminal search should be much more performant now - `/` is no longer needed to enable filter syntax and filters are compiled once instead of re-interpreting the string for each item in the list
  - Terminals now have the option to check and attempt to repair attached storage. For drives, this combines any stray stacks of the same item and forces a contigious sequence of entries.
  - The Controller and various buses have had their shading redone to better suit the style of the terminal, and the Drive Bay has been shined up a bit.

### Stardust Core+Lite
- Added an outline to the Quickbar button glyph to match the style of the other icons
- `input.lua` is now properly resilient against displacement (fixes issues caused by hooks)
- Added `tasks.lua`, a coroutine helper
- Added `itemutil.lua` to Stardust Core Lite
- Added filter precompilation to `itemutil.lua` - create filter once and run on multiple items

### Stardust Core
- Modernized `network.lua` somewhat; pool objects now use method syntax (`pool:tagged()`) and are keyed by object ID instead of sequentially
- `pool:delta(old)` - compares two pools and lists IDs added and removed
- Reworked `interop.lua` slightly - added `exec()` and changed `hack()` to use it

#### metaGUI
- Theming backend improvements (`extAsset`)
- Tool tip generation is now handled by the theme, allowing for far greater visual customization
- New layout attribute: `canvasBacked`
- Fixed an issue where backspacing the beginning of a textBox would duplicate the text
- Text boxes can now be scrolled with the scroll wheel when contents exceed their width
