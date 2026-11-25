extends Node2D


# TODO:
    # Constrain the total length of the rope better DONE
    #       -> Continue by making dynamic solver strength more dynamic, cutting corners, etc
    # Make rotation constraint stable               DONE
    # Add accelerating forces                       DONE
    # Refine paradigm to account for things like splitting the rope
    # Interpolation                                 DONE
    #       -> Note that this is most effective when the minimum distance constraint does not equal the maximum
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
# Mechanics
@export var solver_power:float = 1
@export var dynamic_solving_power:bool = true           # Will iterate solver until global constraints are satisfied. Often computationally feasible because it keeps things in check for future time steps, but must be used carefully (possible weird behavior if solver fails to converge). Visually results in a less stretchy rope. 
@export var external_force:Vector2 = Vector2.ZERO
@export var gravity:float = 0
@export var damp:float = 1

# Visuals
@export var width:float = 8
@export var invisible:bool = false
@export var interpolate_catmull_rom:bool = true         # becomes more effective when min and max distance constraints are different
@export var interpolate_b_spline:bool = false           # very good at smoothing with just 5-10 points, but does not truly interpolate  
                                                        #   this means that it is best for purely graphic stuff; even then, need to implement
                                                        #   the ability to force it to go through at least one point (probably constraining point)
@export var interpolate_factor:int = 5 
@export var limit_visual_rope_length:bool = false

# Internal variables:
var points:Array[Point] = []
var prev_points:Array[Point] = []
var prev_prev_points:Array[Point] = []
var constraining_points:Array[int] = []

# Called when the node enters the scene tree for the first time.
func _ready():
    for i in range(N):
        points.append(Point.new())
        line.add_point(Vector2.ZERO)
    points[0].position = Vector2.UP
    prev_points = points.duplicate()
    prev_prev_points = points.duplicate()

    # Visual
    line.width = width
    if invisible: line.color = Color(0,0,0,0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    # exclude each other :(
    if limit_visual_rope_length:
        var current_length = 0
        for p in range(len(points)):
            line.points[p] = points[p].position
            if p>0: current_length += (points[p].position - points[p-1].position).length()
            if current_length > (N-1)*max_distance_constraint: 
                line.points[p] = line.points[p-1]
    elif interpolate_catmull_rom: 
        var block = Array()
        block.resize((interpolate_factor)*(N-1) + 1)
        line.points = block
        for p in range(0,N-1):
            var p1 = p - 1 if p>0 else 0
            var p2 = p
            var p3 = p+1
            var p4 = p+2 if p<N-2 else p+1
            var t1 = (points[p3].position - points[p1].position)/ (2. if p!=0 else 1.)
            var t2 = (points[p4].position - points[p2].position)/ (2. if p!=N-2 else 1.)

            line.points[p*interpolate_factor] = points[p].position
            for i in range(1,interpolate_factor):
                var t = float(i)/interpolate_factor
                var H = [2*t**3-3*t**2+1, t**3-2*t**2+t, -2*t**3+3*t**2, t**3-t**2]
                line.points[p*interpolate_factor + i] = H[0]*points[p2].position + H[1]*t1 + H[2]*points[p3].position + H[3]*t2

        line.points[-1] = points[-1].position
    elif interpolate_b_spline:
        # Note: Ripped (almost) straight from an AI (deepseek). I just wanted to see how b-spline would look and it's actually great (with 
        #       some cons).
        #       I don't feel motivated to learn it -- not that different than catmull-rom, just different enough to be a lot of effort --
        #       so I'm taking the evil route. Should come back to this later
        var segments = points.size() - 3
        var block = Array()
        block.resize(interpolate_factor * segments + 1)
        line.points = block

        for seg in range(segments):
            # Four consecutive control points for this segment
            var p0 = points[seg].position
            var p1 = points[seg+1].position
            var p2 = points[seg+2].position
            var p3 = points[seg+3].position
            
            # Generate points along this segment
            for i in range(interpolate_factor + 1):
                var t = float(i) / interpolate_factor
                var t2 = t * t
                var t3 = t2 * t
                
                # B-spline basis functions (sum to 1, all non-negative)
                var b0 = (1 - t) * (1 - t) * (1 - t) / 6.0  # (1-t)³/6
                var b1 = (3*t3 - 6*t2 + 4) / 6.0
                var b2 = (-3*t3 + 3*t2 + 3*t + 1) / 6.0
                var b3 = t3 / 6.0
                
                var point = b0 * p0 + b1 * p1 + b2 * p2 + b3 * p3
                line.points[seg * interpolate_factor + i] = point



    else:
        for p in range(len(points)):
            line.points[p] = points[p].position

    
 
func _physics_process(_delta):
    kinematics()
    print(compute_rope_length())


# =================================================== BEHAVIOR ===========================================================


func kinematics():
    # Record current time step (for Verlet Integration)
    for point in points:
        point.set_prev_position()

    # Apply velocity to get future time step
    for p in range(N):
        points[p].position += damp * (points[p].velocity + Vector2(0,gravity) + external_force)
    # Constrain 
    solve_constraints() 

    # Calculate the new velocity using Verlet (applies inertia)
    for p in range(N):
        points[p].set_velocity()


func solve_constraints():
    # Header
    if dynamic_solving_power:                                   # see dynamic_solving_power
        solve_constraints_dynamic()
        return

    # Body:
    for i in range(2+solver_power*floor(sqrt(N))):
        solve()

    reset_constraining_points()


func solve_constraints_dynamic():
    # Goal is to keep constraints under control

    # State info
    #var current_length = compute_rope_length()
    var i = 0

    # Main loop
    #   While we have yet to satisfiably enforce constraints globally. Must make sure we are enforcing them locally as well (i >= 5)
    while (dynamic_heuristic() or i<5) and i<500: # (current_length > 1.1*max_length or current_length < (10./11.)*min_length or i < 5) and i<500:
        solve()
        #current_length = compute_rope_length()
        i += 1
        # print(current_length," ",1.5*max_length," ",.9*min_length) # debug

    reset_constraining_points()

func solve():
    # Solve constraints forward
    for p in range(N-1):
        resolve_distance(p, p+1)                                        # distance
        resolve_rotation(p)                                             # rotation
        if points[p].anchored: points[p].position = points[p].anchor    # anchors (fixed points)
    # Solve them backwards
    for p in range(N-1,0,-1): 
        resolve_distance(p, p-1)
        resolve_rotation(p)
        if points[p].anchored: points[p].position = points[p].anchor
    

# A heuristic to decide whether or not we are done solving
# Includes:
    # Length
    # Angles
func dynamic_heuristic():
    # Parameters
    var max_length = max_distance_constraint*(N-1)
    var min_length = min_distance_constraint*(N-1)
    var min_curvature = rotation_constraint*(N-2)


    # Body:
    var rope_length = 0.    # sum of lengths
    var rope_curvature = 0. # sum of minimum absolute valued angles

    for p in range(N-1):
        rope_length += ( points[p+1].position - points[p].position ).length()
        if p < N-2: rope_curvature += abs(((points[p].position - points[p+1].position).angle_to(points[p+2].position - points[p+1].position)))
    
    var length_flag = rope_length > 1.1*max_length or rope_length < .9*min_length
    var curvature_flag = rope_curvature < .95*min_curvature
    return length_flag or curvature_flag 
    


func reset_constraining_points():
    for p in constraining_points:
        points[p].rm_anchor()
    constraining_points = []


# For external actors
func move_point(p:int, pos:Vector2):
    points[p].set_anchor(pos)
    constraining_points.append(p)

# =============================================== CONSTRAINTS ===============================================================

# Constrain a point based on another point (typically left or right). This usually creates bad physics
func constrain_point(p:int, p0:int):
    # Apply distance constraints
    constrain_distance(p,p0)

    # Apply rotation constraint
    constrain_rotation(p,p0)

 
func constrain_distance(p:int, p0:int):
    var diff = points[p].position - points[p0].position
    points[p].position = min(max_distance_constraint, diff.length()) * diff.normalized() + points[p0].position
    diff = points[p].position - points[p0].position
    points[p].position = max(min_distance_constraint, diff.length()) * diff.normalized() + points[p0].position


func constrain_rotation(p:int, p0:int):
    # Note that this function may use a point that will be updated later

    var p00 = p0 - (p - p0)

    # If point cannot be constrained (too close to origin or destination)
    if p00 < 0 or p00 >= N: return

    var constrainee_diff = points[p].position - points[p0].position
    var constrainer_diff = points[p00].position - points[p0].position

    var is_valid = abs(constrainee_diff.angle_to(constrainer_diff))>rotation_constraint
    if not is_valid:
        var direction = 1 if constrainer_diff.angle_to(constrainee_diff) > 0 else -1
        points[p].position = constrainer_diff.rotated(direction * rotation_constraint) + points[p0].position
        

# Enforces both distance constraints for two points. Splits the burden equally between them
#   There is some advanced math behind this but it should be intuitive
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


func resolve_rotation(p:int):
    if 0 >= p or p >= N-1:
        return
    
    var u = points[p-1].position - points[p].position
    var v = points[p+1].position - points[p].position
    var alpha = u.length() * v.length() * cos(rotation_constraint)                      # this is u dot v where u and v are correctly angled

    if u.dot(v) <= alpha: return

    var lambda = (alpha - u.dot(v))/(v.length_squared() + u.length_squared() + (u+v).length_squared())
    points[p-1].position += lambda * v
    points[p].position -= lambda * (u+v)
    points[p+1].position += lambda * u






func resolve_rotation_(p:int):
    if 0 >= p or p >= N-1:
        return

    var left_vec = points[p-1].position - points[p].position
    var right_vec = points[p+1].position - points[p].position

    var delta = right_vec.angle_to(left_vec)    # don't get the order wrong!
    var dist = abs(delta)

    if dist < rotation_constraint and dist > 0:
        var relative_violation = (rotation_constraint - dist)/dist
        points[p-1].position = points[p].position + left_vec.rotated(.5 * relative_violation * delta)
        points[p+1].position = points[p].position + right_vec.rotated(-.5 * relative_violation * delta)



# ===================================================== UTILITY ==============================================================
func compute_rope_length() -> float:
    var total = 0.
    for p in range(N-1):
        total += ( points[p+1].position - points[p].position ).length()
    return total

func get_shuffled(thing:Array):
    var shuffled = thing
    shuffled.shuffle()
    return shuffled

func get_first_point():
    return(0)

# ===================================================== DEBUG ================================================================

