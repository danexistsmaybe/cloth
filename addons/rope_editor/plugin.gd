@tool
extends EditorPlugin


const Rope = preload("res://fabrics/scripts/rope.gd")


# = PARAMETERS = 
const GRAB_RADIUS = 8.0                         # pixels


# = STATE VARIABLES = 
var rope : Node2D = null                        # the rope in question
var drag_index := -1                            # index of the point being dragged, or -1
var points_before : PackedVector2Array          # a record used for leaving positions untouched for undos


# Runs when the plugin enters the ScenetTree
func _enter_tree():
    print("Rope Editor: on")
    # Fires on every change to the undo history, including undo and redo
    get_undo_redo().history_changed.connect(update_overlays)


# Runs when the plugin exits the SceneTree
func _exit_tree():
    print("Rope Editor: off")
    get_undo_redo().history_changed.disconnect(update_overlays)


# Runs every time a node gets selected
func _handles(object):
    var script = object.get_script()
    # Walk up its inheritance 
    while script != null:
        if script == Rope:
            return true # we're in business ;)
        script = script.get_base_script()
    return false


# Called after _handles returns true
func _edit(object):
    rope = object
    drag_index = -1
    if rope:
        print("Rope Editor: editing ", rope.name)
    update_overlays()   # ask the editor to redraw


# Called after _handles returns something new
func _make_visible(visible):
    if not visible:
        if rope:
            print("Rope Editor: done with ", rope.name)
        rope = null
        drag_index = -1
        update_overlays()


# Receive an event. Returning true stops the editor from also using the event
func _forward_canvas_gui_input(event):
    if rope == null or not rope.is_inside_tree():
        return false

    var to_screen : Transform2D = rope.get_viewport_transform() * rope.get_global_transform()

    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
        if event.pressed:   
            var screen_points : PackedVector2Array = to_screen * rope.points
            var local_mouse : Vector2 = to_screen.affine_inverse() * event.position
            points_before = rope.points.duplicate()         # record points for an undo

            drag_index = find_point(screen_points, event.position)
            if drag_index == -1:          # not a point: maybe add one
                if event.ctrl_pressed:    # if ctrl, append
                    drag_index = insert_point(rope.points.size(), local_mouse)
                else:                     # if above a segment, insert
                    var segment := find_segment(screen_points, event.position)
                    if segment == -1:
                        return false
                    drag_index = insert_point(segment + 1, local_mouse)
            return true
        else:
            if drag_index != -1:          # point was released
                finish_drag()
                return true

    # Straighten
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_L and event.shift_pressed and not event.ctrl_pressed and drag_index == -1:
            straighten()
            return true

    # Right click on a point removes it
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
        var index := find_point(to_screen * rope.points, event.position)
        if index != -1 and drag_index == -1:
            remove_point(index)
            return true

    # Drag
    if event is InputEventMouseMotion and drag_index != -1:
        # Leave original untouched in the undo history
        var new_points : PackedVector2Array = rope.points.duplicate()
        new_points[drag_index] = to_screen.affine_inverse() * event.position
        rope.points = new_points
        update_overlays()
        return true

    return false


# Is there a point under the mouse? -> if true, index, otherwise -1
func find_point(screen_points : PackedVector2Array, mouse : Vector2) -> int:
    for i in range(screen_points.size()):
        if screen_points[i].distance_to(mouse) <= GRAB_RADIUS:
            return i
    return -1


# Is there a segment under the mouse (segment i joins points i and i+1), or -14
func find_segment(screen_points : PackedVector2Array, mouse : Vector2) -> int:
    for i in range(screen_points.size() - 1):
        var closest := Geometry2D.get_closest_point_to_segment(mouse, screen_points[i], screen_points[i+1])
        if closest.distance_to(mouse) <= GRAB_RADIUS:
            return i
    return -1


# Add a point at index and return that index. finish_drag records it for undo
func insert_point(index : int, position : Vector2) -> int:
    var new_points : PackedVector2Array = rope.points.duplicate()
    new_points.insert(index, position)
    rope.points = new_points
    update_overlays()
    return index


func remove_point(index : int):
    if rope.points.size() <= 2:             # a rope needs 2+ points
        return
    points_before = rope.points.duplicate()
    var new_points : PackedVector2Array = rope.points.duplicate()
    new_points.remove_at(index)
    rope.points = new_points
    commit_points("Remove rope point")


# Record the drag as an undo/redo action
func finish_drag():
    drag_index = -1
    if rope.points != points_before:
        commit_points("Edit rope points")


# Space the points from first to last
func straighten():
    var n : int = rope.points.size()
    if n < 3: return

    points_before = rope.points.duplicate()
    var new_points : PackedVector2Array = rope.points.duplicate()
    for i in range(1, n - 1):
        new_points[i] = points_before[0].lerp(points_before[-1], float(i) / (n - 1))
    if new_points == points_before: return
    
    rope.points = new_points
    commit_points("Straighten rope")


# Add the change from points_before to the current points to the undo history
func commit_points(action_name : String):
    var undo_redo := get_undo_redo()
    undo_redo.create_action(action_name)
    undo_redo.add_do_property(rope, "points", rope.points.duplicate())
    undo_redo.add_undo_property(rope, "points", points_before)
    undo_redo.commit_action()


# The method requested by update_overlays
func _forward_canvas_draw_over_viewport(overlay):
    if rope == null or not rope.is_inside_tree():
        return

    # Translate each point from local to global, then from global to viewport
    var to_screen : Transform2D = rope.get_viewport_transform() * rope.get_global_transform()
    var screen_points : PackedVector2Array = to_screen * rope.points

    # Draw the editor line
    if screen_points.size() >= 2:
        overlay.draw_polyline(screen_points, Color.ORANGE, 2.0)
    for p in screen_points:
        overlay.draw_circle(p, 6.0, Color.WHITE)
        overlay.draw_circle(p, 4.0, Color.ORANGE)
