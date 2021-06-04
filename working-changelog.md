### StarTech
- Migrated Telepad bookmarks to a player property

### Stardust Core
- Migrated several status properties to player properties
- New Quickbar conditions: `playerProperty(key, value)`, `statusProperty(key, value)`
  - Returns whether the property is "true" if no value specified, otherwise a deep comparison

#### metaGUI
- Migrated settings table into a property ID in line with `mod:id` convention
