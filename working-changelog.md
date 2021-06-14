### Stardust Core+Lite
- Added tech hooks for grabbing player input (however, only vanilla techs are patched)

#### metaGUI
- Fixed horizontal scrolling
- Added horizontal scroll bars
- Themes can specify directives for the default scroll bar animation
  - Carbon now has accent-colored scroll bars
- Fixed `checkShift()` causing especially strange behavior if player's items are disabled (lounging, in sphere tech)
- Added a fast path in `checkShift()` when Stardust Core tech hooks are present
  - `fastCheckShift()` to try *only* the fast path
