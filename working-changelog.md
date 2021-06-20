### Stardust Core+Lite
- Added an outline to the Quickbar button glyph to match the style of the other icons

### Stardust Core
- Modernized `network.lua` somewhat; pool objects now use method syntax (`pool:tagged()`) and are keyed by object ID instead of sequentially
- `pool:delta(old)` - compares two pools and lists IDs added and removed
- Added `tasks.lua`, a coroutine helper
- Reworked `interop.lua` slightly - added `exec()` and changed `hack()` to use it

#### metaGUI
- Theming backend improvements (`extAsset`)
- Tool tip generation is now handled by the theme, allowing for far greater visual customization
- New layout attribute: `canvasBacked`
