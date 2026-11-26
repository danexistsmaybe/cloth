# How the simulation works

## The pieces

- A [Particle](fabrics/particle.md) is a point with a position and a velocity.
- A **constraint** is a rule about particles, such as "these two stay 20 pixels apart".
- A [SoftBody](fabrics/soft_body.md) is a node that holds particles and constraints.
- A [Puppet](fabrics/puppet.md) is the SoftBody that actually simulates them.

## Building a body from the scene tree

Bodies are assembled by nesting nodes. For a draggable rope:

```
Puppet
└── Handle
    └── Rope
        └── Line2D      (marks where the rope starts and ends)
```

Godot calls `_ready` on children before their parents. Each SoftBody uses this to take its children's particles and constraints:

1. `Rope` creates its particles and constraints.
2. `Handle` copies them, empties the rope's constraint list, and adds its own constraint.
3. `Puppet` copies everything from `Handle` and empties that list too.

The result:

- **Constraints** end up only in the topmost SoftBody, so each one is solved once.
- **Particles** are listed at every level. The lists point to the same objects, so a rope can still draw and adjust its own.

A SoftBody tree does not move unless there is a `Puppet` at or above it.

## Joining bodies

Nesting bodies under one Puppet makes them simulate together, but does not connect them. To connect them, do one of the following in a script on a common parent, after `super._ready()`.

**Share a particle.** `glue_particles([keep, other, ...])` replaces every `other` with `keep`, so the bodies meet at one point:

```gdscript
extends SoftBody

func _ready():
    super._ready()
    glue_particles([$RopeA.particles[-1], $RopeB.particles[0]])
```

The joint uses the position and settings of `keep`. It swings freely unless you add a `MIN_ANGLE` constraint across it. A rope copies its own `gravity` and `damp` to its particles every tick, so for a shared particle the last rope in the tree wins.

**Add a constraint between them.** This links two particles without merging them:

```gdscript
add_constraint([constraint.EXACT_DISTANCE, $RopeA.particles[-1], $RopeB.particles[0], 20.0])
```

## What happens each physics tick

The Puppet:

1. Remembers every particle's position.
2. Moves each particle by `damp * (velocity + gravity + external_force + impulse)`.
3. Solves the constraints repeatedly, in list order.
4. Resolves collisions.
5. Sets each velocity to the distance moved this tick (Verlet integration).

Velocity, gravity and impulse are measured in pixels per tick, not per second. Changing the physics tick rate changes how everything moves.

The solver repeats at least 5 and at most 500 times. It stops once the total length of all distance constraints is no more than 110% of the target and the total angle is at least 90% of the target. These totals cover the whole Puppet, so one badly stretched joint can be hidden by many good ones.

## Constraints

A constraint is a plain array: the type, then the particles, then any numbers. Types are in the `SoftBody.constraint` enum.

| Type | Array after the type | Effect | Counted by the stop test |
| --- | --- | --- | --- |
| `MAX_DISTANCE` | `p1, p2, max` | Keeps two particles within `max` | Yes |
| `MIN_DISTANCE` | `p1, p2, min` | Keeps them at least `min` apart | No |
| `MIN_MAX_DISTANCE` | `p1, p2, min, max` | Both of the above | Yes (`max`) |
| `EXACT_DISTANCE` | `p1, p2, distance` | Holds a fixed distance | Yes |
| `MIN_ANGLE` | `p1, middle, p3, radians` | Keeps the angle at `middle` at least this wide; `PI` is straight | Yes |
| `MIN_ANGLE_2` | `p1, middle, p3, radians` | Similar, but only pushes `p1` and `p3` apart | No |
| `POSITION` | `p, Vector2` | Pins a particle to a point | No |
| `HANDLE` | `p` | Moves the particle to the mouse while the button is held | No |

`GLUE` is in the enum but the solver ignores it.

Code may change a number in a constraint while the game runs, for example to lengthen a rope. Because the arrays are untyped, a change to a layout also has to be made in `Puppet.solve`, `Puppet.heuristic` and anywhere else that reads that position.

## Adding your own constraints

In a SoftBody subclass, the position of `super._ready()` matters:

- **Before it:** you can still edit a child's constraints, such as changing segment lengths.
- **After it:** you have all the children's particles, so you can connect them to each other, pin them, or merge them with `glue_particles`.

Leaving out `super._ready()` means children are not collected at all.

`archive/grass_blade.gd` is an example that does both. It no longer runs from its current location.

## Positions

Particle positions are **global** coordinates. Rope drawing, collision raycasts and mouse dragging all rely on this.

A body's starting position follows its nodes: their position, rotation and scale, including every parent's, are applied once, when the body is created. Moving a node while the game runs does not move its particles.

Only positions are transformed. Segment lengths and other constraint values are always in pixels, so scaling a node does not scale them.

## Collision

Collision is off until a particle has `collision = true`. No current fabric turns it on, so your code has to:

```gdscript
for p in particles:
    p.collision = true
    p.collision_mask = 0b0001   # physics layers to hit
```

Each tick the Puppet casts a ray from the particle's old position to its new one and reflects it off anything hit. Only particles collide: the line between two particles can pass through an obstacle. [Surface](fabrics/surface.md) controls how much speed survives a bounce.

The project names physics layers 1 to 4 Environment, Player, Creature and Object.
