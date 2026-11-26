# Particle

A single simulated point.

Script: `fabrics/scripts/particle.gd`. Inherits `Resource`.

## Settings

These are plain variables, set from code. They do not appear in the inspector.

| Variable | Default | Meaning |
| --- | --- | --- |
| `position` | `(0, 0)` | Current global position |
| `prev_position` | `(0, 0)` | Position at the start of the tick |
| `velocity` | `(0, 0)` | Movement per tick |
| `gravity` | `(0, 0)` | Added to the movement every tick |
| `external_force` | `(0, 0)` | Also added every tick; nothing uses it yet |
| `impulse` | `(0, 0)` | A one-off push, cleared after one tick. Add to it with `apply_impulse` |
| `damp` | `1.0` | Multiplies the whole movement; below 1 loses energy |
| `collision` | `false` | Whether the particle collides |
| `collision_mask` | `0b11111111` | Physics layers it collides with |

## Known issues

- There is no mass: constraints always move both particles equally.
- `Particle` extends `Resource`, but none of its variables are exported, so they are not saved with a scene.
