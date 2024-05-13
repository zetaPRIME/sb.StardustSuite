### StarTech
- Removed power cost of Nanofield double jump (why should it cost FP when vanilla techs are free?)
- Slightly reworked Augpack lighting; should behave identically to before, but may be slightly more efficient

### Stardust Core

### Stardust Core+Lite
- **eventHook**: thread-global event subscription and calling
- [wip] HUD manager
- Added an important PSA

#### metaGUI
- Added Slider widget
- Client extension (StarExtensions etc.) integration
  - Scroll wheel events count the number of notches moved per frame so you can scroll faster
  - Better/more reliable shift hold checks
  - Basic cut/copy/paste for text fields
  - Logless fallback resolution where applicable
  - Window resizing (not supported by StarExtensions at this time)
- Text box height is now determined by the theme. (It can be manually specified, otherwise it defaults to the height of the background asset.)
- Fixed a bug where list items (including tabs) would exhibit strange behavior with buttons other than left and right click
- Added uninit() for widgets
- Added explicit width for labels
- Added wrap toggle for labels (on by default)
- Expanded initial mouse search range dramatically to encompass even the most extreme resolutions

### Stardust Core Lite
- Added missing entry for Chroma theme (whoops)

### Stardust UI
(0.1.6...)
