### StarTech
- Autosmelter now places outputs in existing stacks if present (this includes input slots, so refeeding is possible)
- Autosmelter "take all" now pulls input slot items if no recipe for them exists, or if there aren't enough to start smelting
- All tiers of Flux Relay now also serve as Transmatter Network relays
- Storage bus direction indicators now only show when holding a wrench or wire tool
- AP gain and Nanofield costs have been rebalanced
- Pulsestrike Glaive beam damage has been adjusted to bring it more in line with its melee DPS
- Fixed Elytra accelerating oddly in water and other fluids with Frackin Universe installed
- Ending flight can now be buffered during blink dash

### Stardust Core
- The Quickbar is now powered by metaGUI, and is therefore themable and can expand to fit items
- Interface scale threshold height increased to a more useful value than the vanilla defaults
- `stardustlib:holdingTool` property in client-side string metatable for held item's `stardustlib:toolType` item attribute
- mention dynitemanim
- Fixed AP being granted incorrectly when an entity "dies" without actually being killed (relocator, capture pod)

#### metaGUI
- Toggle mode for UI uniqueness (`"uniqueMode" : "toggle"`)
