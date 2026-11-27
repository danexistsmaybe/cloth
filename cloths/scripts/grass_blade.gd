# A rope with a pinned root that tapers to a point.
# The first point is the root and the last is the tip.
extends "res://fabrics/scripts/rope.gd"


func _ready():
    super._ready()

    # Pinning two particles holds the root's direction as well as its position
    for p in range(2):
        add_constraint([constraint.POSITION, particles[p], particles[p].position])

    # Full width at the root, nothing at the tip
    var taper := Curve.new()
    taper.add_point(Vector2(0, 1), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
    taper.add_point(Vector2(1, 0), 0, 0, Curve.TANGENT_LINEAR, Curve.TANGENT_LINEAR)
    line.width_curve = taper


# Keep the spacing the points were drawn with
func get_segment_constraints(i:int) -> Array:
    var length := to_global(points[i]).distance_to(to_global(points[i+1]))
    return [length, length]
