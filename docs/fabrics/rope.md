# Rope

A chain of particles drawn as a line.

Script: `fabrics/scripts/rope.gd`. Scene: `fabrics/rope.tscn`. Inherits [SoftBody](soft_body.md).

## Using it

1. Put the rope somewhere under a [Puppet](puppet.md).
2. Give it a child `Line2D` named exactly `Line2D`. Its first and last points set where the rope starts and ends. They follow the guide, the rope and its parents, so what you see in the editor is where the rope starts.
3. Set `max_distance_constraint` and `min_distance_constraint` to the segment length you want. The default of 1 pixel is almost never right. To start at rest, use the guide line's length on screen (including any scaling) divided by `N - 1`.

**The `Line2D` guide is required.** Without it all particles start at the same point and the whole rope becomes `NaN`. The exceptions are if your code moves the particles apart before the first physics tick, or if `min_distance_constraint` is 0.

The guide is deleted once the rope has read it. Moving the rope node while the game runs does not move the rope. Scaling a node spreads out the starting points but not the segment lengths, so the rope pulls back to its set length.

## Settings

| Setting | Default | Meaning |
| --- | --- | --- |
| `N` | 10 | Number of particles |
| `line_resource` | none | A `Line2D` scene that styles the rope, such as `resources/renders/grass_resource.tscn` |
| `max_distance_constraint` | 1 | Longest a segment can be |
| `min_distance_constraint` | 1 | Shortest a segment can be. Equal to max gives a fixed length; 0 gives no minimum |
| `rotation_constraint` | `PI/2` | Narrowest angle between segments, in radians. 0 turns it off |
| `gravity` | 0 | Downward pull, pixels per tick per tick |
| `damp` | 1 | Below 1 loses energy |
| `width` | 8 | Line width. Ignored when `line_resource` is set |
| `color` | white | Line colour. Ignored when `line_resource` is set |
| `interpolate_catmull_rom` | `true` | Smooth curve through every particle |
| `interpolate_b_spline` | `false` | Smoother curve that only passes near particles. Only used when Catmull-Rom is off; needs `N` of at least 4 |
| `interpolate_factor` | 5 | Drawn points per segment |
| `invisible` | `false` | Currently has no effect |

`gravity` and `damp` are copied to the rope's particles every tick, so change them on the rope; values set on the particles are overwritten. `width` and `color` can be changed while running.

## Known issues

- No guide line means `NaN`, with no error message.
- `invisible` does nothing.
- A style with a gradient shows the gradient and ignores `color`.
- The B-spline curve stops short of both ends of the rope.
- `_draw` and `polygonize` are empty placeholders. The empty `_draw` also stops `debug_particle_physics` from drawing anything.
- If a parent node moves while the game runs, the drawn line moves with it and drifts from its particles.
