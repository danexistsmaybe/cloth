extends SoftBody

@export var length := 50.
var segment_length : float


var rope : SoftBody

# Called when the node enters the scene tree for the first time.
func _ready():
    rope = $Rope
    segment_length = length/4.


    for C in rope.constraints:
        if C[0] == constraint.EXACT_DISTANCE:
            C[-1] = segment_length

    super._ready()

    add_constraint([constraint.POSITION, rope.particles[1], global_position])
    add_constraint([constraint.POSITION, rope.particles[0], global_position + Vector2(0,segment_length)])

    for P in particles:
        P.collision = true
        P.collision_mask = 0b1110



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass
