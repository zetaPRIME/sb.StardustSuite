### StarTech
- Removed power cost of Nanofield double jump (why should it cost FP when vanilla techs are free?)

### Stardust Core

### Stardust Core+Lite
- **eventHook**: thread-global event subscription and calling
- [wip] HUD manager

#### metaGUI
- Added Slider widget
- StarExtensions integration
  - Scroll wheel events count the number of notches moved per frame so you can scroll faster
  - Better/more reliable shift hold checks
  - Basic cut/copy/paste for text fields
  - Logless fallback resolution
- Text box height is now determined by the theme. (It can be manually specified, otherwise it defaults to the height of the background asset.)
- Fixed a bug where list items (including tabs) would exhibit strange behavior with buttons other than left and right click
- Added uninit() for widgets
- Added explicit width for labels

### Stardust UI
(0.1.6...)
