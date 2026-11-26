# Handle

Lets the mouse drag a particle.

Script: `fabrics/scripts/handle.gd`. Scene: `fabrics/handle.tscn`. Inherits [SoftBody](soft_body.md).

This is different from `utility/handle.gd`, which only drives the archived prototypes.

## Using it

Nest the body to be dragged **under** the handle, with the handle under a [Puppet](puppet.md). Place the handle on a particle (within 1 pixel), such as the first point of a rope's guide line.

While the left mouse button (the `mouse_down` action) is held, that particle follows the mouse. This is by design:

- A click anywhere pulls every handle's particle to the mouse; the click does not need to be nearby.
- Releasing the button lets the particle move freely again. A handle does not pin anything in place.

## How it works

At start-up it adds a `HANDLE` constraint for each descendant particle less than 1 pixel from the handle's global position.

## Known issues

- If no particle is within 1 pixel, nothing happens and no warning is printed.
