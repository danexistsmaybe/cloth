# HardBody

One particle that moves a hitbox, so that other particles can collide with it.

Script: `fabrics/scripts/hard_body.gd`. No scene: attach the script to a `Node2D`. Inherits [SoftBody](soft_body.md).

## Using it

Give it a child named `Hitbox`, normally a `StaticBody2D` with a collision shape, and place it under a [Puppet](puppet.md).

## How it works

It creates one particle at the node's global position, and each frame moves `Hitbox` there. A rotated or scaled parent still rotates or resizes the hitbox.

## Known issues

- It is not a rigid body: it is a single point with a shape attached, and does not rotate.
- The hitbox moves once per rendered frame, not once per physics tick.
- The hitbox is not pushed back by the particles that hit it.
- It does not call `super._ready()`, so SoftBody children are ignored.
