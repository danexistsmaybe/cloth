# Cloth documentation

A custom 2D soft-body system for Godot 4.2, meant for video games and animation. The goals are that it is easy to use, fast and robust. Games are the main target, so efficiency matters most.

Start with [How the simulation works](architecture.md), then read the page for the fabric you need.

## Fabrics

There is one page per script in `fabrics/scripts/`.

| Fabric | What it is |
| --- | --- |
| [SoftBody](fabrics/soft_body.md) | Base node that collects particles and constraints |
| [Particle](fabrics/particle.md) | A single simulated point |
| [Puppet](fabrics/puppet.md) | Runs the simulation for everything under it |
| [Rope](fabrics/rope.md) | A chain of particles drawn as a line |
| [Handle](fabrics/handle.md) | Lets the mouse drag a particle |
| [Sprite](fabrics/sprite.md) | One particle that moves a `Sprite2D` |
| [HardBody](fabrics/hard_body.md) | One particle that moves a physics hitbox |
| [Surface](fabrics/surface.md) | Sets how bouncy a collider is |

## Keeping these pages up to date

- A change to a script in `fabrics/scripts/` updates its page in the same piece of work.
- A new script gets a new page with the same file name, and a row in this index.
- A script moved to `archive/` has its page and index row removed.
- Behaviour shared by several fabrics belongs in [architecture.md](architecture.md); other pages link to it.
- Record bugs under **Known issues** on the fabric's page, and delete them once fixed.

Each fabric page follows this outline, leaving out sections that do not apply:

```markdown
# Name

One sentence on what it is.

Script, scene, and what it inherits from.

## Using it
## Settings
## How it works
## Known issues
```
