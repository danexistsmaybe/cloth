extends SoftBody

# = Parameters = 
@export var line_resource : PackedScene
# Starting shape, in local coordinates: one particle per point. Edit with the Rope Editor plugin
@export var points : PackedVector2Array = PackedVector2Array([Vector2(0, 0), Vector2(0, 100)])

# Constraints:
@export_group("Constraints")
@export var max_distance_constraint:float = 1.
@export var min_distance_constraint:float = 1.
# This is the minimum angular distance between one segment and another
@export var rotation_constraint:float = PI/2

# Settings:
# Mechanics
@export_group("Physics")
@export var gravity:float = 0
@export var damp:float = 1
 
# Visuals
@export_group("Visual")
@export var width:float = 8
@export var color:Color = Color(1,1,1,1)
@export var invisible:bool = false
@export var interpolate_catmull_rom:bool = true         # becomes more effective when min and max distance constraints are different
@export var interpolate_b_spline:bool = false           # very good at smoothing with just 5-10 points, but does not truly interpolate  
                                                        #   this means that it is best for purely graphic stuff; even then, need to implement
                                                        #   the ability to force it to go through at least one point (probably constraining point)
@export var interpolate_factor:int = 5                  # the number of interpolated points (including the real point) to render


# Number of particles, taken from points
var N : int

# Rendering
var line : Line2D
 

func _ready():
    # Create particles, one at each point
    N = points.size()
    assert(N >= 2, "A rope needs at least two points")
    add_n_particles(N, damp, gravity)
    for p in range(N):
        particles[p].position = to_global(points[p])

    # Create distance constraints
    for i in range(N-1):
        var distances : Array = get_segment_constraints(i)
        var minimum : float = distances[0]
        var maximum : float = distances[1]
        if minimum == maximum:
            add_constraint([constraint.EXACT_DISTANCE, particles[i], particles[i+1], maximum])
        elif minimum == 0:
            add_constraint([constraint.MAX_DISTANCE, particles[i], particles[i+1], maximum])
        else:
            add_constraint([constraint.MIN_MAX_DISTANCE, particles[i], particles[i+1], minimum, maximum])
    
    # Create rotation constraints
    if rotation_constraint:
        for i in range(1,N-1):
            add_constraint([constraint.MIN_ANGLE, particles[i-1], particles[i], particles[i+1], rotation_constraint])
    
    line = Line2D.new() if line_resource == null else line_resource.instantiate()
    if line_resource != null:
        width = line.width
        color = line.default_color
    add_child(line)
    line.global_transform = Transform2D.IDENTITY
    

# Override to build constraints differently
func get_segment_constraints(_i:int) -> Array:
    return [min_distance_constraint, max_distance_constraint]


func _draw():
    pass
    #var points_to_render = get_points_to_render()
    #var polygon = polygonize(points_to_render)
    #draw_polyline(points_to_render, color, width, true)

func _process(_delta):
    render_line()

func _physics_process(_delta):
    for p in particles:
        p.gravity.y = gravity
        p.damp = damp


# =================================================================================================================================
func render_line():
    line.width = width
    line.default_color = color
    var render_points = get_points_to_render()
    #for p in render_points: p *= 0
    line.points = render_points
 
func polygonize(line:PackedVector2Array):
    pass
    # "Polygons will always connect its last defined point to its first one in order to have a closed shape."
    

func get_points_to_render():
    if not (interpolate_b_spline or interpolate_catmull_rom):
        return get_point_positions()
    
    return get_interpolated_point_positions()

func get_point_positions():
    var positions = PackedVector2Array()
    positions.resize(N)
    for i in range(N):
        positions[i] = particles[i].position
    return positions

func get_interpolated_point_positions():
    if interpolate_catmull_rom:
        var block = PackedVector2Array()
        block.resize((interpolate_factor)*(N-1) + 1)
        for p in range(0,N-1):
            var p1 = p - 1 if p>0 else 0
            var p2 = p
            var p3 = p+1
            var p4 = p+2 if p<N-2 else p+1
            var t1 = (particles[p3].position - particles[p1].position)/ (2. if p!=0 else 1.)
            var t2 = (particles[p4].position - particles[p2].position)/ (2. if p!=N-2 else 1.)
 
            block[p*interpolate_factor] = particles[p].position
            for i in range(1,interpolate_factor):
                var t = float(i)/interpolate_factor
                var H = [2*t**3-3*t**2+1, t**3-2*t**2+t, -2*t**3+3*t**2, t**3-t**2]
                block[p*interpolate_factor + i] = H[0]*particles[p2].position + H[1]*t1 + H[2]*particles[p3].position + H[3]*t2
        block[-1] = particles[-1].position
        return block
    elif interpolate_b_spline:
        # Note: Ripped (almost) straight from an AI (deepseek). I just wanted to see how b-spline would look and it's actually great (with 
        #       some cons). I don't feel motivated to learn it -- not that different than catmull-rom, just different enough to be a lot of 
        #       effort -- so I'm taking the evil route. Should come back to this later
        var segments = particles.size() - 3
        var block = PackedVector2Array()
        block.resize(interpolate_factor * segments + 1)

        for seg in range(segments):
            # Four consecutive control particles for this segment
            var p0 = particles[seg].position
            var p1 = particles[seg+1].position
            var p2 = particles[seg+2].position
            var p3 = particles[seg+3].position
            
            # Generate particles along this segment
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
                block[seg * interpolate_factor + i] = point
        return block
    else:
        return get_point_positions()
