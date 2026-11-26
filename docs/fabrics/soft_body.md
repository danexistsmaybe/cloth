# SoftBody

The base node of the system: it holds particles and constraints and collects them from its children.

Script: `fabrics/scripts/soft_body.gd`. Inherits `Node2D`. It does not simulate; see [Puppet](puppet.md).

## Using it

Use it directly to group several bodies under one node, or extend it to make a new fabric. See [How the simulation works](../architecture.md) for the order in which things are collected.

## Settings

| Setting | Default | Meaning |
| --- | --- | --- |
| `debug_particle_physics` | `false` | Draws velocity in blue and applied forces in red |

## Methods

| Method | What it does |
| --- | --- |
| `add_n_particles(n, damp, gravity)` | Creates `n` particles. They all start at `(0, 0)`, so move them before simulating |
| `add_constraint(array)` | Adds a constraint |
| `glue_particles([keep, other, ...])` | Replaces the other particles with `keep` in this body and its descendants, joining bodies at one point |
| `submit_soft_body()` | Sends a body created at runtime up to the topmost SoftBody |
| `annihilate()` | Removes this body's particles, every constraint that uses them, and the node |

## Creating bodies at runtime

A body added after the scene has started is not collected automatically. Either set `submit_self = true` before adding it, or call `submit_soft_body()` afterwards. Remove it with `annihilate()`, not `queue_free()`, or its particles stay in the simulation.

## Known issues

- Calling `submit_soft_body()` on a body whose parent is not a SoftBody adds a second copy of its own particles and constraints.
- A submitted body reaches only the topmost SoftBody. Nodes in between do not list its particles.
- `glue_particles` prints on every call.
- Debug drawing only works on `SoftBody` and `Handle`. `Rope` replaces `_draw` with an empty one, and `Puppet`, `Sprite` and `HardBody` replace `_process`, so their overlay never updates.
