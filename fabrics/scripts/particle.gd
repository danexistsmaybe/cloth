class_name Particle
extends Resource

var position:Vector2
var prev_position:Vector2
var velocity:Vector2
var impulse:Vector2
var external_force:Vector2
var gravity:Vector2
var damp:float

var collision : bool
var collision_mask : int



#enum heuristic {
#    NONE,               # solve a fixed factor of times
#    MAX_DISTANCE,       # overall max distance, one parameter
#    MIN_DISTANCE,       # overall min distance, one parameter (not so useful)
#    MIN_ANGLE           # overall min angle, one parameter
#}

 
func _init():
    position = Vector2.ZERO
    prev_position = Vector2.ZERO
    velocity = Vector2.ZERO
    impulse = Vector2.ZERO
    external_force = Vector2.ZERO
    gravity = Vector2.ZERO
    damp = 1.

    collision = false
    collision_mask = 0b11111111
    

func set_prev_position():
    prev_position = position

func set_velocity():
    velocity = position - prev_position

func physics():
    #print(position)
    position += damp * (velocity + gravity + external_force + impulse)
    impulse = Vector2.ZERO

func apply_impulse(F:Vector2):
    impulse += F

func copy_parameters_from(P:Particle):
    velocity = P.velocity
    impulse = P.impulse
    external_force = P.external_force
    gravity = P.gravity
    damp = P.damp

    collision = P.collision
    collision_mask = P.collision_mask
