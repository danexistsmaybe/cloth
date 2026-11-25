extends Node2D


# TODO:
    # Constrain the total length of the rope better
    # Make rotation constraint stable
    # Add accelerating forces
    # Refine paradigm to account for things like splitting the rope
    # Construct multiropes
    # Render in three dimensions
    #
    # Refine paradigm until collision logic is possible
    #
    # Create a creature that eats goo
    # Give the creature pain




@onready var line:Line2D = $Line2D

# = Parameters = 
@export var N:int = 10

# Constraints:
@export var max_distance_constraint:float = 1.
@export var min_distance_constraint:float = 1.
# This is the minimum angular distance between one segment and another
@export var rotation_constraint:float = PI/2

# Settings:
@export var external_force:Vector3 = Vector3.ZERO
@export var gravity:float = 0


# Internal variables:
var points:Array[Point3D] = []
var prev_points:Array[Point3D] = []
var prev_prev_points:Array[Point3D] = []
var constraining_points:Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready():
    for i in range(N):
        points.append(Point3D.new())
        line.add_point(Vector2.ZERO)
    prev_points = points.duplicate()
    prev_prev_points = points.duplicate()
 
 
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    var width_curve = Curve.new()
    for p in range(len(points)):
        var x = points[p].position.x
        var y = points[p].position.y
        var z = points[p].position.z
        if z == 0: z = .000001
        line.points[p] = Vector2(
            x/z,
            y/z
        )
        var w = 0 if z <= 0 else 1/z
        width_curve.add_point(Vector2(p/N, w))
    line.width_curve = width_curve

 
func _physics_process(_delta):
    # Try moving every point and then constraining from the center -> outwards
    # OR constraining from the outside -> in, resolving the two halves at the end
    
    kinematics()
    print(compute_rope_length())

func kinematics():
    # Apply forces
    #for point in points:
        # Linear forces
        #point.velocity += (external_force + Vector2(0,gravity))
        # Dampening (Friction)
        #point.velocity *= .995    # currently arbitrary not even sure this will do anything
    #prev_prev_points = prev_points.duplicate(true)
    #prev_points = points.duplicate(true)

    for point in points:
        point.prev_position = point.position

    for p in range(N):
        points[p].position += points[p].velocity #+ Vector3(0,0,.1)

    # Constrain 
    solve_constraints() 

    for p in range(N):
        points[p].velocity = points[p].position - points[p].prev_position

func solve_constraints():
    for i in range(2+floor(sqrt(N))):
        for p in range(len(points)-1):
            #resolve_rotation(p) 
            resolve_distance(p, p+1)
            if points[p].anchored: points[p].position = points[p].anchor

    #for p in range(len(points)-1,0,-1):
        #constrain_point(p-1, p)
    for p in constraining_points:
        points[p].rm_anchor()


func move_point(p:int, pos:Vector2):
    points[p].set_anchor(Vector3(pos.x, pos.y, 1))
    constraining_points.append(p)
 
# Constrain a point based on another point (typically left or right) WITHOUT generating inertia
func constrain_point(p:int, p0:int):
    # Apply distance constraints
    constrain_distance(p,p0)

    # Apply rotation constraint
    #constrain_rotation(p,p0)

#func resolve_points(p1:int, p2:int):
#    resolve_distance(p1,p2)

#    resolve_rotation(p1)

func constrain_point_halfway(p:int, p0:int):
    # Apply distance constraints
    constrain_distance_halfway(p,p0)

    # Apply rotation constraint
    #constrain_rotation_halfway(p,p0)


# Constrain a point based on another point (typically left or right) and generate inertia
# p is point being constrained, p0 is point constraining it
func snap_point(p:int, p0:int):
    var prev = points[p].position

    constrain_point(p, p0)

    # Generate inertia if point was constrained
    #   note that this cancels all previous velocity, and could be very large. In theory this is physically accurate
    var delta = points[p].position - prev
    points[p].velocity = (points[p].velocity + delta)/1.4
    #if delta.length() > 0: points[p].velocity = delta

 
func constrain_distance(p:int, p0:int):
    var diff = points[p].position - points[p0].position
    points[p].position = min(max_distance_constraint, diff.length()) * diff.normalized() + points[p0].position
    diff = points[p].position - points[p0].position
    points[p].position = max(min_distance_constraint, diff.length()) * diff.normalized() + points[p0].position


        
func constrain_distance_halfway(p:int, p0:int):
    var pre = points[p].position
    constrain_distance(p,p0)
    points[p].position += .5 * (pre - points[p].position)


func resolve_distance(p1:int, p2:int):
    var delta = points[p1].position - points[p2].position
    var dist = (delta).length()
    if dist > max_distance_constraint:
        var relative_violation = (max_distance_constraint - dist)/dist
        points[p1].position += .5 * relative_violation * (delta)
        points[p2].position -= .5 * relative_violation * (delta)
    if dist < min_distance_constraint and dist > 0:
        var relative_violation = (min_distance_constraint - dist)/dist
        points[p1].position += .5 * relative_violation * (delta)
        points[p2].position -= .5 * relative_violation * (delta)

"""func resolve_rotation(p:int):
    if 0 >= p or p >= N-1:
        return

    var left_vec = points[p-1].position - points[p].position
    var right_vec = points[p+1].position - points[p].position

    var delta = right_vec.angle_to(left_vec)    # don't get the order wrong!
    var dist = abs(delta)

    if dist < rotation_constraint and dist > 0:
        var relative_violation = (rotation_constraint - dist)/dist
        points[p-1].position = points[p].position + left_vec.rotated(.5 * relative_violation * delta)
        points[p+1].position = points[p].position + right_vec.rotated(-.5 * relative_violation * delta)"""






# Geometry stuff
#func get_closer_angle#(theta1, theta2):

func get_shuffled(thing:Array):
    var shuffled = thing
    shuffled.shuffle()
    return shuffled

# ===================================================== DEBUG ================================================================
func compute_rope_length():
    var total = 0.
    for p in range(N-1):
        total += ( points[p+1].position - points[p].position ).length()
    return total