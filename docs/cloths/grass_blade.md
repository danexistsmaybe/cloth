# GrassBlade

A green rope with a pinned root that tapers to a point.

Script: `cloths/scripts/grass_blade.gd`. Scene: `cloths/grass_blade.tscn`. Inherits [Rope](../fabrics/rope.md).

## Using it

1. Add `grass_blade.tscn` somewhere under a [Puppet](../fabrics/puppet.md).
2. Shape it with the [Rope Editor plugin](../rope_editor.md). The first point is the root and the last is the tip.
3. Put the root a little below the ground surface, and place the Puppet above the ground in the scene tree so the ground is drawn over the buried part.

## Settings

| Setting | Value in the scene | Meaning |
| --- | --- | --- |
| `points` | 8 points, 10 px apart, going up | Starting shape, one particle per point |
| `rotation_constraint` | 2.9 | Stiffness: the narrowest angle between segments, in radians. `PI` is straight |
| `damp` | 0.9 | Below 1 loses energy |
| `width` | 6 | Width at the root |
| `color` | green | Line colour |

The other [Rope](../fabrics/rope.md) settings also apply, except `max_distance_constraint` and `min_distance_constraint`: each segment keeps the length it was drawn with.

## How it works

The two lowest particles are pinned with `POSITION` constraints, which holds both the root's position and its direction. Keep the second point below ground too if you do not want to see a stiff base.

The taper is a `width_curve` on the rope's line.

## Known issues

- Nothing moves the blade yet: there is no wind, handle or collision.
- It has no spring back to upright. A bent blade only straightens as far as `rotation_constraint` requires.
- A bend sharper than `rotation_constraint` straightens as soon as the scene runs.
