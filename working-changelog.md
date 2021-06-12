### StarTech


### Stardust Core
- General settings tab
  - Toggle for whether or not to automatically dismiss the Quickbar when selecting an item
  - Scrolling modes: wheel only, fling only or both
- `blockAutoDismiss` flag on quickbar items

#### metaGUI
- Radio buttons: give a checkBox a `radioGroup` attribute and a `value`, get result with `getGroupValue()`, or `getGroupChecked()` to get the widget itself
- Broadcast events can now give return values. Note that broadcasting now short-circuits on the first returning event if return value is nonboolean.
- `wideBroadcast()` - same as `broadcast()` except from a specified number of levels up in the widget heirarchy
- Tabs are now styled differently from list items
- Tabs now have `visible` and `color` attributes and matching `setVisible()` and `setColor()` methods
- `isHD` flag for ninepatch assets (renders at double resolution)
- Scrollwheel fixes (phantom scrolling, brokenness when window is partially offscreen)
