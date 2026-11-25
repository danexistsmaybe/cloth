extends Line2D

@export var edge_size:float = 2.
@export var rope_length:int = 100
@export var gravity:float = 9.8

var point_velocities := []

# Called when the node enters the scene tree for the first time.
func _ready():
    for i in range(rope_length):
        add_point(Vector2(0,0))
        point_velocities.append(Vector2(0,0))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    pass

func _physics_process(_delta):
    points[0] = get_parent().global_position
    for p in range(1,len(points)):
        move_point(p)

func move_point(p):
    # Apply forces
    point_velocities[p] += gravity*Vector2(0,1)
    points[p] += point_velocities[p]
    
    # Apply constraints
    var p0 = points[p]
    points[p] = edge_size*(points[p] - points[p-1]).normalized() + points[p-1]
    if (p0-points[p]).length() > 0: point_velocities[p] = 0

