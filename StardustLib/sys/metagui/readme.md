# metaGUI - a primer
(highly WIP)

## Your first UI
A pane using metaGUI is a JSON document (as with vanilla panes), typically with the extension `.ui`, though this is not required.
#### Document structure
```jsonc
{ // Basic attributes:
  "style" : "window", // This can be: window (default, has a titlebar), panel (just a simple frame)
  "size" : [320, 200], // This is the *internal* size of your UI layout, excluding window decorations.
  "title" : "metaGUI example pane", // The displayed title in "window" mode. Does nothing otherwise.
  "icon" : "icon.png", // Path can be relative or absolute. Recommended to be 18x18 pixels or smaller.
  "accentColor" : "3f3fff", // An accent color can be specified as a hexcode, or default to the theme's.
  "scripts" : ["script.lua"], // Paths can be relative or absolute.
  
  // Extra attributes:
  "openWithInventory" : true, // Same as in a vanilla pane: opens the inventory when the window opens,
  // closes the inventory when the window closes (and vice versa), and opens the window beside it.
  "anchor" : ["bottomRight", [-16, -24]], // Anchors the window a side, corner, or the center of the
  // screen. Positions are left to right and top to bottom; the above anchor has the edges of the window
  // 16 pixels away from the right, and 24 pixels from the bottom.
  "uniqueBy" : "path", // Closes any previous window with the same document path when a new one is opened.
  // Most useful for UI not bound to an entity, such as with Quickbar entries.
  
  "children" : [ // Finally, the layout syntax. Notice how this is an *array*, unlike vanilla panes;
    // widget names are optional, as metaGUI is largely heirarchy- and layout-based.
    { "mode" : "horizontal" }, // If the "type" field is omitted, the first object is used as parameters
    // for the layout itself. Here, we set the root layout to horizontal (default is vertical).
    [ // Arrays (with at least one item) are treated as sub-layouts; if the parent layout is in vertical
      // mode, sub-layouts default to horizontal, otherwise they default to vertical as usual.
      { "type" : "label", "text" : "Here is a simple label. Formatting works as usual." },
      { "type" : "image", "file" : "picture.png" } // Widgets can use relative paths as well.
    ], [ // Our second implicit sub-layout, on the right-hand side.
      { "size" : 80 }, // This time we use our parameter object to give our sidebar a fixed width.
      { "type" : "button", "caption" : "Top button.", "id" : "btnTop" }, // Widgets with an "id" parameter
      // have a reference to their table placed in the scripts' global scope with the same value as key.
      { "type" : "button", "caption" : "Another button.", "color" : "accent" }, // Buttons and other
      // widgets can specify a highlight color, either as a hexcode or the window's accent color.
      "spacer", // An expanding spacer can be placed implicitly with the string "spacer", or a fixed-size
      // one with an integer value. (A negative-size spacer can even be used to reduce default spacing.)
      { "type" : "button", "caption" : "And this one is on the bottom!"}
    ]
  ]
}
```


mention registry
