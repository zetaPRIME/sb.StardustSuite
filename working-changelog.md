### StarTech
- Autosmelter now places outputs in existing stacks if present (this includes input slots, so refeeding is possible)
- Autosmelter "take all" now pulls input slot items if no recipe for them exists, or if there aren't enough to start smelting
- All tiers of Flux Relay now also serve as Transmatter Network relays
- Storage bus direction indicators now only show when holding a wrench or wire tool
- Fixed Elytra accelerating oddly in water and other fluids with Frackin Universe installed
- Ending flight can now be buffered during blink dash

### Stardust Core
- `stardustlib:holdingTool` property in client-side string metatable for held item's `stardustlib:toolType` item attribute

#### metaGUI
- Toggle mode for UI uniqueness (`"uniqueMode" : "toggle"`)
