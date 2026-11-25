extends SoftBody

# Called when the node enters the scene tree for the first time.
func _ready():
    super._ready()
    


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

func _physics_process(delta):
    if len(constraints) > 0:
        kinematics()

    #print(len(constraints), " constraints")
    #for c in constraints:
        #print(c)



func kinematics():
    # Record current time step (for Verlet Integration)
    for particle in particles:
        particle.set_prev_position()

    # Apply velocity to get future time step
    for particle in particles:
        particle.physics()
        
    # Constrain 
    solve_constraints()

    # Collision
    collide()

    # Calculate the new velocity using Verlet (applies inertia)
    for particle in particles:
        particle.set_velocity()

func collide():
    var allowed_ricochets = 5
    for p in particles:
        if p.collision:
            var cast_start = p.prev_position

            # Check multiple times in case of ricochet (helps in corners)
            for i in range(allowed_ricochets):
                # Raycast
                var space_state = get_world_2d().direct_space_state
                var query = PhysicsRayQueryParameters2D.create(cast_start, p.position, p.collision_mask)
                var result = space_state.intersect_ray(query)

                if not result: break
                if result:
                    if i < 2:
                        var friction = 1 if not result.collider.get_parent() is Surface else result.collider.get_parent().friction
                        # var bounce = result.collider.get_parent().bounce

                        # Reflect BOTH position and previous position over the surface normal
                        var norm = result.normal.normalized()
                        p.position = result.position + friction*(p.position - result.position).bounce(result.normal.normalized())
                        p.prev_position = result.position + friction*(p.prev_position - result.position).bounce(result.normal.normalized())
                        cast_start = result.position + .01*norm    # godot uses .001 margins for collisions

                    # On the last bounce, let's just place the object as close to the surface as 
                    #   possible and give it zero velocity.
                    if i == allowed_ricochets - 1: 
                        p.position = result.position + .01*result.normal
                        p.prev_position = p.position

func solve_constraints():
    # Goal is to keep constraints under control

    # State info
    #var current_length = compute_rope_length()
    var i = 0

    # Main loop
    #   While we have yet to satisfiably enforce constraints globally. Must make sure we are enforcing them locally as well (i >= 5)
    while (heuristic() or i<5) and i<500: # (current_length > 1.1*max_length or current_length < (10./11.)*min_length or i < 5) and i<500:
        solve()
        i += 1

func solve():
    # Solve constraints forward
    for c in constraints: 
        if c[0] == constraint.MAX_DISTANCE:
            solve_max_distance(c[1],c[2],c[3])
        elif c[0] == constraint.MIN_DISTANCE:
            solve_min_distance(c[1],c[2],c[3])
        elif c[0] == constraint.MIN_MAX_DISTANCE:
            solve_max_distance(c[1],c[2],c[4])
            solve_min_distance(c[1],c[2],c[3])
        elif c[0] == constraint.EXACT_DISTANCE:
            solve_exact_distance(c[1],c[2],c[3])
        elif c[0] == constraint.MIN_ANGLE:
            solve_min_angle(c[1],c[2],c[3],c[4])
        elif c[0] == constraint.MIN_ANGLE_2:
            solve_min_angle_2(c[1],c[2],c[3],c[4])
        #elif c[0] == constraint.ANGLE_RANGE:
        #    solve_angle_range(c[1],c[2],c[3],c[4],c[5])
        elif c[0] == constraint.POSITION:
            solve_position(c[1],c[2])
        elif c[0] == constraint.HANDLE:
            handle(c[1])


# A heuristic to decide whether or not we are done solving
# Includes:
    # Max length
    # Angles
func heuristic():
    # Parameters
    var total_length = 0
    var max_length = 0
    var total_curvature = 0
    var min_curvature = 0

    # Body:
    for c in constraints:
        if c[0] == constraint.MAX_DISTANCE or c[0] == constraint.EXACT_DISTANCE:
            total_length += (c[1].position - c[2].position).length()
            max_length += c[3]
        elif c[0] == constraint.MIN_MAX_DISTANCE:
            total_length += (c[1].position - c[2].position).length()
            max_length += c[4]
        elif c[0] == constraint.MIN_ANGLE:
            total_curvature += abs((c[1].position - c[2].position).angle_to(c[3].position - c[2].position))
            min_curvature += c[4]
    
    var length_flag = total_length > 1.1*max_length
    var curvature_flag = total_curvature < .9*min_curvature
    return length_flag or curvature_flag 
    

# =============================================== CONSTRAINTS ===============================================================

func solve_max_distance(p1:Particle, p2:Particle, constraint:float):
    var delta = p1.position - p2.position
    var dist = (delta).length()
    if dist > constraint:
        var relative_violation = (constraint - dist)/dist
        p1.position += .5 * relative_violation * (delta)
        p2.position -= .5 * relative_violation * (delta)

func solve_min_distance(p1:Particle, p2:Particle, constraint:float):
    var delta = p1.position - p2.position
    var dist = (delta).length()
    if dist < constraint and dist > 0:
        var relative_violation = (constraint - dist)/dist
        p1.position += .5 * relative_violation * (delta)
        p2.position -= .5 * relative_violation * (delta)

func solve_exact_distance(p1:Particle, p2:Particle, constraint:float):
    var delta = p1.position - p2.position
    var dist = (delta).length()
    var relative_violation = (constraint - dist)/dist
    p1.position += .5 * relative_violation * (delta)
    p2.position -= .5 * relative_violation * (delta)

func solve_min_angle(p1:Particle, p2:Particle, p3:Particle, constraint:float):
    var u = p1.position - p2.position
    var v = p3.position - p2.position
    var alpha = u.length() * v.length() * cos(constraint)          # this is u dot v where u and v are correctly angled

    if u.dot(v) <= alpha: return

    var lambda = (alpha - u.dot(v))/(v.length_squared() + u.length_squared() + (u+v).length_squared())
    p1.position += lambda * v
    p2.position -= lambda * (u+v)
    p3.position += lambda * u

func solve_min_angle_2(p1:Particle, p2:Particle, p3:Particle, constraint:float):
    var a = (p1.position - p2.position).length()
    var b = (p3.position - p2.position).length()
    solve_min_distance(p1, p3, sqrt(a**2+b**2 - 2*a*b*cos(constraint)))

"""func solve_angle_range(p1:Particle, p2:Particle, p3:Particle, C1:float, C2:float):
    var u = p1.position - p2.position
    var v = p3.position - p2.position
    var alpha = u.length() * v.length() * cos(constraint)          # this is u dot v where u and v are correctly angled

    if u.dot(v) <= alpha: return

    var lambda = (alpha - u.dot(v))/(v.length_squared() + u.length_squared() + (u+v).length_squared())
    p1.position += lambda * v
    p2.position -= lambda * (u+v)
    p3.position += lambda * u"""

func solve_position(p1:Particle, pos:Vector2):
    p1.position = pos 

func handle(particle:Particle):
    if Input.is_action_pressed("mouse_down"):
        particle.position = get_global_mouse_position()
