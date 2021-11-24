### StarTech

### Stardust Core

### Stardust Core+Lite

#### metaGUI
- Item slot cache is now deep copied on successful save; this is marginally slower but fixes mutability issues (fixes pulse weapons' skill trees failing to save the item)
- Added "force" flag to `itemSlot:setItem()` to bypass cache check entirely
- Fixed a logged error in `killKeysub` when IPC table not yet created

### Stardust UI
