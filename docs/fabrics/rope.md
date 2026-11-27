# Rope

A chain of particles drawn as a line.

Script: `fabrics/scripts/rope.gd`. Scene: `fabrics/rope.tscn`. Inherits [SoftBody](soft_body.md).

## Using it

1. Put the rope somewhere under a [Puppet](puppet.md).
2. Place its `points` in the 2D viewport with the [Rope Editor plugin](../rope_editor.md). There is one particle per point, starting where the point is. They follow the rope's and its parents' position, rotation and scale.
3. Set `max_distance_constraint` and `min_distance_constraint` to the segment length you want. The default of 1 pixel is almost never right, and the spacing of your points does not change it.

A rope needs at least two points. Moving the rope node while the game runs does not move the rope.

## Segment constraints

`get_segment_constraints(i)` returns `[minimum, maximum]` for the segment from particle `i` to `i + 1`. By default every segment gets `min_distance_constraint` and `max_distance_constraint`. A subclass can override it, for example to keep the drawn spacing:

```gdscript
func get_segment_constraints(i:int) -> Array:
    var length := to_global(points[i]).distance_to(to_global(points[i+1]))
    return [length, length]
```

It is called once per segment, when the rope is created.

## Settings

| Setting | Default | Meaning |
| --- | --- | --- |
| `line_resource` | none | A `Line2D` scene that styles the rope, such as `resources/renders/grass_resource.tscn` |
| `points` | (0, 0), (0, 100) | Starting shape in local coordinates, one particle per point. The particle count `N` is taken from it |
| `max_distance_constraint` | 1 | Longest a segment can be |
| `min_distance_constraint` | 1 | Shortest a segment can be. Equal to max gives a fixed length; 0 gives no minimum |
| `rotation_constraint` | `PI/2` | Narrowest angle between segments, in radians. 0 turns it off |
| `gravity` | 0 | Downward pull, pixels per tick per tick |
| `damp` | 1 | Below 1 loses energy |
| `width` | 8 | Line width. Ignored when `line_resource` is set |
| `color` | white | Line colour. Ignored when `line_resource` is set |
| `interpolate_catmull_rom` | `true` | Smooth curve through every particle |
| `interpolate_b_spline` | `false` | Smoother curve that only passes near particles. Only used when Catmull-Rom is off; needs at least 4 points |
| `interpolate_factor` | 5 | Drawn points per segment |
| `invisible` | `false` | Currently has no effect |

`gravity` and `damp` are copied to the rope's particles every tick, so change them on the rope; values set on the particles are overwritten. `width` and `color` can be changed while running.

## Known issues

- Two points in the same place give `NaN` if their segment has a fixed length.
- `invisible` does nothing.
- A style with a gradient shows the gradient and ignores `color`.
- The B-spline curve stops short of both ends of the rope.
- `_draw` and `polygonize` are empty placeholders. The empty `_draw` also stops `debug_particle_physics` from drawing anything.
- If a parent node moves while the game runs, the drawn line moves with it and drifts from its particles.
