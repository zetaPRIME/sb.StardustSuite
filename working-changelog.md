### StarTech
- Removed power cost of Nanofield double jump (why should it cost FP when vanilla techs are free?)
- Slightly reworked Augpack lighting; should behave ~~identically~~ very similar to before, but may be slightly more efficient
- Augpack lighting now smoothly attenuates with ambient light levels

### Stardust Core

### Stardust Core+Lite
- **sharedTable**: load-time metatable smuggling made clean and easy
- **eventHook**: thread-global event subscription and calling
- [wip] HUD manager
- Added an important PSA

#### metaGUI
- Added Slider widget
- Client extension (StarExtensions and OpenStarbound) integration
  - Scroll wheel events count the number of notches moved per frame so you can scroll faster
  - Better/more reliable shift hold checks
  - Basic cut/copy/paste for text fields
  - Logless fallback resolution where applicable
  - Window resizing (OSB only)
  - Position memory (OSB only)
- Added per-pane state memory (`metagui.state`)
- Text box height is now determined by the theme. (It can be manually specified, otherwise it defaults to the height of the background asset.)
- Fixed a bug where list items (including tabs) would exhibit strange behavior with buttons other than left and right click
- Fixed lua error on creating a tab with no title (oops)
- Fixed layout thrashing with setVisible()
- Added uninit() for widgets
- Added explicit width for labels
- Added wrap toggle for labels (on by default)
- Added `padding` for panels
- Expanded initial mouse search range dramatically to encompass even the most extreme resolutions
- Added hard sync between paired container stubs and panes (if one closes, it'll actively close the other)
  - This fixes erratic behavior that may be exhibited in OSB CI builds.

### Stardust Core Lite
- Added missing entry for Chroma theme (whoops)

### Stardust UI
- [ph] Inventory pane replacement (OSB only)
- [ph] Take All hotkey
