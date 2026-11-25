extends Node2D

@export var edge_size:float = 10.
@export var rope_length:int = 30
@export var gravity:float = 1
@export var rotate_end_point:bool = true

@export var origin_dir := Vector2(0,0)
@export_range(0, 360, 0.1, "degrees") var arc_constraint:float = 90.


@onready var line:Line2D = $Line
@onready var endpoint:Sprite2D = $EndPoint

var damp := .9
var constraint_scalar := .2

var point_velocities:Array[Vector2] = []
var point_inertias:Array[Vector2] = []

# Called when the node enters the scene tree for the first time.
func _ready():
    for i in range(rope_length):
        line.add_point(Vector2(0,0))
        point_velocities.append(Vector2(0,0))
        point_inertias.append(Vector2(0,0))

    arc_constraint = deg_to_rad(arc_constraint)

 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
    pass

func _physics_process(_delta):
    line.points[0] = global_position
    for p in range(1,len(line.points)):
        apply_constraints(p)
        apply_forces(p)
    endpoint.global_position = line.points[-1]
    if rotate_end_point:
        endpoint.rotation = (line.points[-2] - line.points[-1]).angle()

func apply_constraints(p):
    var delta = constrain(p)
    # Inertia
    point_velocities[p] -= point_inertias[p]
    point_inertias[p] = delta.normalized()

func apply_forces(p):
    point_velocities[p] = point_velocities[p] + Vector2(0,gravity) + point_inertias[p]

    line.points[p] += point_velocities[p]

    constrain(p)

    var dir = (line.points[p]-line.points[p-1]).normalized()
    point_velocities[p] -= constraint_scalar * point_velocities[p].dot(dir)*dir
    point_velocities[p] *= damp
    

"""func move_point(p):
    # Apply forces
    point_velocities[p] = point_velocities[p] + Vector2(0,gravity)
    line.points[p] += point_velocities[p]
    
    # Apply constraints
    var p0 = line.points[p]
    line.points[p] = edge_size*(line.points[p] - line.points[p-1]).normalized() + line.points[p-1]
    point_velocities[p] -= .01*point_velocities[p].dot(p0-line.points[p]) * (p0-line.points[p]).normalized()
    #if (p0-points[p]).length() > 0: point_velocities[p] = Vector2(0,0)
    # Inertia
    point_velocities[p] += (line.points[p]-p0).normalized()"""

func constrain(p):
    var p0 = line.points[p]
    line.points[p] = edge_size*(line.points[p] - line.points[p-1]).normalized() + line.points[p-1]
    return line.points[p] - p0