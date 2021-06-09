### StarTech
- Migrated Telepad bookmarks to a player property

### Stardust Core
- Migrated several status properties to player properties
- New Quickbar conditions: `playerProperty(key, value)`, `statusProperty(key, value)`
  - Returns whether the property is "true" if no value specified, otherwise a deep comparison

#### metaGUI
- **Scroll wheel support!** This includes smooth wheel scrolling for scrollAreas and wheel zoom in skill trees.
  - Relevant widget functions: `isWheelInteractable()`, `onMouseWheelEvent(dir)`
- New widget: `tabField`
- `subscribeEvent` functions changed to include `self` parameter (oops)
- Fixed panel explicit size
- `expandMode` for list items
- `expandMode` plus `inline` and `expand` flags for buttons
- More correct consideration of `scrollDirections` on scrollAreas
- Migrated settings table into a property ID in line with `mod:id` convention
