extends Node2D

@export var line_resource:PackedScene

# = Parameters = 
## Rows
@export var rows:int = 10
## Columns
@export var columns:int = 10

# Constraints:
@export_group("Constraints")
@export var max_distance_constraint:float = 1.
@export var min_distance_constraint:float = 1.
## The minimum angular distance between one segment and another
@export var rotation_constraint:float = PI/2

# Settings:
@export_group("Settings")
# Mechanics
@export_subgroup("Mechanics")
@export var solver_power:float = 1
@export var dynamic_solving_power:bool = true           # Will iterate solver until global constraints are satisfied. Often computationally feasible because it keeps things in check for future time steps, but must be used carefully (possible weird behavior if solver fails to converge). Visually results in a less stretchy rope. 
@export_subgroup("Physics")
@export var external_force:Vector2 = Vector2.ZERO
@export var gravity:float = 0
@export var damp:float = 1

# Visuals
@export_group("Visuals")
@export var width:float = 8
@export var invisible:bool = false
#@export var interpolate_catmull_rom:bool = true         # becomes more effective when min and max distance constraints are different
#@export var interpolate_b_spline:bool = false           # very good at smoothing with just 5-10 points, but does not truly interpolate  
                                                        #   this means that it is best for purely graphic stuff; even then, need to implement
                                                        #   the ability to force it to go through at least one point (probably constraining point)
#@export var interpolate_factor:int = 5 
#@export var limit_visual_rope_length:bool = false

# Internal variables:
var points:Array[Array] = []
var constraining_points:Array[Array] = []
var lines:Array[Line2D] = []

func _ready():
    # Create points
    for r in range(rows):
        points.append([])
        for c in range(columns):
            points[r].append(Point.new())
            points[r][c].position = Vector2(r*max_distance_constraint, c*max_distance_constraint)
    points[0][0].position = Vector2.UP

    # Instantiate lines
    for r in range(rows + columns):
        var line = line_resource.instantiate()
        for i in range(rows if r < rows else columns):
            line.add_point(Vector2.ZERO)
        # Visual
        line.width = width
        if invisible: line.color = Color(0,0,0,0)
        lines.append(line)
        add_child(line)

func _process(_delta):
    for r in range(rows):
        for c in range(columns):
            lines[r].points[c] = points[r][c].position
            lines[rows+c].points[r] = points[r][c].position

func _physics_process(_delta):
    kinematics()
    for r in rows:
        print(points[r][0].position," ",points[r][1].position)
    print("")


# =================================================== BEHAVIOR ===========================================================


func kinematics():
    # Record current time step (for Verlet Integration)
    for r in range(rows):
        for c in range(columns):
            points[r][c].set_prev_position()

    # Apply velocity to get future time step
    for r in range(rows):
        for c in range(columns):
            points[r][c].position += damp * (points[r][c].velocity + Vector2(0,gravity) + external_force)
    # Constrain 
    solve_constraints() 

    # Calculate the new velocity using Verlet (applies inertia)
    for r in range(rows):
        for c in range(columns):
            points[r][c].set_velocity()


func solve_constraints():
    # Header
    if dynamic_solving_power:                                   # see dynamic_solving_power
        solve_constraints_dynamic()
        return

    # Body:
    for i in range(2+solver_power*floor(sqrt(rows+columns))):
        solve()

    reset_constraining_points()

func solve_constraints_dynamic():
    # Goal is to keep constraints under control
    var i = 0

    # Main loop
    #   While we have yet to satisfiably enforce constraints globally. Must make sure we are enforcing them locally as well (i >= 5)
    while (dynamic_heuristic() or i<5) and i<500:
        solve()
        i += 1
    reset_constraining_points()

func solve():
    # Solve constraints in a random order. Note that each distance constraint will be resolved twice (each pair)
    for r in get_shuffled(Array(range(rows))):
        for c in get_shuffled(Array(range(columns))):
            for n in get_neighbors([r,c]):
                resolve_distance([r,c],n)                                                      # distance
            #for n in get_diagonals([r,c]):
                #resolve_distance_diagonal([r,c],n)
            resolve_rotation([r,c])                                                          # rotation
            if points[r][c].anchored: points[r][c].position = points[r][c].anchor   # anchors (fixed points)


# A heuristic to decide whether or not we are done solving
# Includes:
    # Length
func dynamic_heuristic():
    # Parameters
    var max_length = max_distance_constraint*(rows-1)*columns + max_distance_constraint*(columns-1)*rows
    var min_length = min_distance_constraint*(rows-1)*columns + min_distance_constraint*(columns-1)*rows
    #var min_curvature = rotation_constraint*(N-2)

    # Body:
    var fabric_length = 0.    # sum of lengths
    #var rope_curvature = 0. # sum of minimum absolute valued angles

    for r in range(rows-1):
        for c in range(columns-1):
            for n in get_neighbors([r,c]):
                fabric_length += (points[r][c].position - points[n[0]][n[1]].position).length()/2
    #if p < N-2: rope_curvature += abs(((points[p].position - points[p+1].position).angle_to(points[p+2].position - points[p+1].position)))
    
    var length_flag = fabric_length > 1.2*max_length or fabric_length < .8*min_length
    #var curvature_flag = rope_curvature < .95*min_curvature
    return length_flag #or curvature_flag 

func reset_constraining_points():
    for p in constraining_points:
        points[p[0]][p[1]].rm_anchor()
    constraining_points = []

# For external actors
func move_point(p:Array, pos:Vector2):
    points[p[0]][p[1]].set_anchor(pos)
    constraining_points.append(p)


# =============================================== CONSTRAINTS ===============================================================
# Enforces both distance constraints for two points. Splits the burden equally between them
#   There is some advanced math behind this but it should be intuitive
func resolve_distance(p1:Array[int], p2:Array):
    #print(p1," ",p2)
    var delta = get_point(p1).position - get_point(p2).position
    var dist = (delta).length()
    if dist > max_distance_constraint:
        var relative_violation = (max_distance_constraint - dist)/dist
        get_point(p1).position += .5 * relative_violation * (delta)
        get_point(p2).position -= .5 * relative_violation * (delta)
    if dist < min_distance_constraint and dist > 0:
        var relative_violation = (min_distance_constraint - dist)/dist
        get_point(p1).position += .5 * relative_violation * (delta)
        get_point(p2).position -= .5 * relative_violation * (delta)

func resolve_distance_diagonal(p1:Array[int], p2:Array):
    #print(p1," ",p2)
    var delta = get_point(p1).position - get_point(p2).position
    var dist = (delta).length()
    if dist < sqrt(2*min_distance_constraint**2)/2 and dist > 0:
        var relative_violation = (min_distance_constraint - dist)/dist
        get_point(p1).position += .5 * relative_violation * (delta)
        get_point(p2).position -= .5 * relative_violation * (delta)


func resolve_rotation(p:Array[int]):
    var neighbors = get_neighbors(p)
    var corners = []
    if len(neighbors) == 2: corners = [[neighbors[0],neighbors[1]]]
    elif len(neighbors) == 3: corners = [[neighbors[0],neighbors[1]],[neighbors[1],neighbors[2]]]
    elif len(neighbors) == 4: corners = [[neighbors[0],neighbors[1]],[neighbors[1],neighbors[2]],[neighbors[2],neighbors[3]],[neighbors[3],neighbors[0]]]
    else: print("ERROR ERROR THIS IS GOOD ERROR HANDLING ERROR THERE SHOULD ONLY BE 2-4 NEIGHBORS")
    
    # A corner is a pair of neighbors
    for corner in corners:
        var u = get_point(corner[0]).position - get_point(p).position
        var v = get_point(corner[1]).position - get_point(p).position
        var alpha = u.length() * v.length() * cos(rotation_constraint)                      # this is u dot v where u and v are correctly angled

        if u.dot(v) <= alpha: return

        var lambda = (alpha - u.dot(v))/(v.length_squared() + u.length_squared() + (u+v).length_squared())
        get_point(corner[0]).position += lambda * v
        get_point(p).position -= lambda * (u+v)
        get_point(corner[1]).position += lambda * u


# ===================================================== UTILITY ==============================================================
#func compute_rope_length() -> float:
#    var total = 0.
#    for p in range(N-1):
#        total += ( points[p+1].position - points[p].position ).length()
#    return total

"""func apply_to_neighbors(foo, p):
    var r = p[0]
    var c = p[1]
    if r > 0: foo.call([r-1,c])
    if r < rows: foo.call([r+1,c])
    if c > 0: foo.call([r,c-1])
    if c < columns: foo.call([r,c+1])

func apply_to_self_and_neighbors(foo, p):
    var r = p[0]
    var c = p[1]
    if r > 0: foo.call(p,[r-1,c])
    if r < rows: foo.call(p,[r+1,c])
    if c > 0: foo.call(p,[r,c-1])
    if c < columns: foo.call(p,[r,c+1])"""

func get_neighbors(p):
    var r:int = p[0]
    var c:int = p[1]
    var neighbors = []
    if r > 0: neighbors.append([r-1,c])
    if c > 0: neighbors.append([r,c-1])
    if r < rows-1: neighbors.append([r+1,c])
    if c < columns-1: neighbors.append([r,c+1])
    return neighbors

func get_diagonals(p):
    var r:int = p[0]
    var c:int = p[1]
    var neighbors = []
    if r > 0 and c > 0: neighbors.append([r-1,c-1])
    if r < rows-1 and c > 0: neighbors.append([r+1,c-1])
    if r < rows-1 and c < columns-1: neighbors.append([r+1,c+1])
    if r > 0 and c < columns-1: neighbors.append([r-1,c+1])
    return neighbors

func get_point(p):
    return points[p[0]][p[1]]
 
func get_shuffled(thing:Array):
    var shuffled = thing
    shuffled.shuffle()
    return shuffled

func get_first_point():
    return([0,0])
