# Puppet

The simulator: it moves, constrains and collides every particle under it.

Script: `fabrics/scripts/puppet.gd`. Scene: `fabrics/puppet.tscn`. Inherits [SoftBody](soft_body.md).

## Using it

Make it the top node of a body and nest other fabrics under it. It has no settings of its own.

It does nothing while it has no constraints. This means a body made only of loose particles, such as a lone [Sprite](sprite.md), does not move.

## How it works

The steps of a tick, the solver's stopping rule and the constraint types are in [How the simulation works](../architecture.md).

Collision allows up to 5 bounces per particle per tick. Position is reflected on the first two; on the fifth the particle is placed against the surface and stopped.

## Known issues

- The solver can run 500 times per tick when a body cannot satisfy its constraints, which is costly for large scenes.
- The stopping rule uses totals, so individual constraints can still be badly violated.
- `EXACT_DISTANCE` between two particles at the same position produces `NaN`, which then spreads through the body.
- Constraints are always solved in the same order.
- Collisions run after constraints, so a collision can leave a constraint violated until the next tick.
