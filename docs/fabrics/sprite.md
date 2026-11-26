# Sprite

One particle that moves an image.

Script: `fabrics/scripts/sprite.gd`. Scene: `fabrics/sprite.tscn`. Inherits [SoftBody](soft_body.md).

## Using it

Give it a child named `Sprite2D`, and place it under a [Puppet](puppet.md). Connect its particle to something with a constraint or a [Handle](handle.md).

Gravity and collision are off unless a parent's script turns them on.

## How it works

It creates one particle at the node's global position, and each frame moves the child sprite there. A rotated or scaled parent still rotates or resizes the image.

## Known issues

- It does not call `super._ready()`, so SoftBody children of a Sprite are ignored.
- Without a `Sprite2D` child it raises an error every frame.
- The name `Sprite` is easy to confuse with Godot's `Sprite2D`.
