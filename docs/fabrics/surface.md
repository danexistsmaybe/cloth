# Surface

Sets how much speed a particle keeps when it bounces off a collider.

Script: `fabrics/scripts/surface.gd`. No scene. Inherits `Node2D`; it is not a SoftBody.

## Using it

Attach the script to the **parent** of a physics body:

```
Node2D  (surface.gd)
└── StaticBody2D
    └── CollisionShape2D
```

## Settings

| Setting | Default | Meaning |
| --- | --- | --- |
| `friction` | 0.9 | Fraction of the bounce that is kept: 1 keeps everything, 0 stops the particle at the surface |
| `bounce` | 1.0 | Not used yet |

Colliders without a Surface parent behave as if `friction` were 1.

## Known issues

- `friction` scales the whole reflected movement, so it acts more like bounciness than friction.
- `bounce` is ignored.
