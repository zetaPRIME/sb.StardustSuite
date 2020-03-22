# metaGUI - a primer
(highly WIP)

## Your first UI
A pane using metaGUI is a JSON document (as with vanilla panes), typically with the extension `.ui`, though this is not required.
#### Document structure
```json
{ // Basic attributes:
  "style" : "window", // This can be: window (default, has a titlebar), panel (just a simple frame)
  "size" : [240, 200], // This is the *internal* size of your UI layout, excluding window decorations.
  "title" : "metaGUI example pane", // The displayed title in "window" mode. Does nothing otherwise.
  "icon" : "icon.png", // Path can be relative or absolute. Recommended to be 18x18 pixels or smaller.
  "scripts" : ["script.lua"], // Paths can be relative or absolute.
  
  // Extra attributes:
  "openWithInventory" : true, // Same as in a vanilla pane: opens the inventory when the window opens, closes
  // the inventory when the window closes (and vice versa), and opens the window beside it if not anchored.
  "anchor" : ["bottomRight", [-16, -24]], // Anchors the window a side, corner, or the center of the screen.
  // Positions are left to right and top to bottom; the above anchor has the edges of the window 16 pixels
  // away from the right, and 24 pixels from the bottom.
  "uniqueBy" : "path", // Closes any previous window with the same document path when a new one is opened.
  // Most useful for UI not bound to an entity.
}
```


mention registry
