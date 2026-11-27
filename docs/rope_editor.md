# Rope Editor plugin

An editor plugin for placing a rope's starting points in the 2D viewport.

Files: `addons/rope_editor/`. Enable it under Project > Project Settings > Plugins.

Selecting a rope (or a script that extends it, such as GrassBlade) draws its `points` over the 2D viewport. The rope builds one particle at each point.

| Action | Effect |
| --- | --- |
| Drag a point | Move it |
| Press on a segment | Insert a point there, which can be dragged straight away |
| Ctrl+click | Add a point to the end |
| Right-click a point | Remove it (two points are always kept) |
| Shift+L | Straighten: space the points evenly between the first and last |
| Ctrl+Z | Undo one whole edit |

The drawing code is `_forward_canvas_draw_over_viewport`. It converts the rope's local points to screen pixels with `get_viewport_transform() * get_global_transform()`.

Input comes through `_forward_canvas_gui_input`, which returns `true` only when it uses the event, so other clicks reach the editor as usual. Each edit is recorded as one undo action. The `history_changed` signal redraws the points after undo and redo.
