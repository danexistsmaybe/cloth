extends Node2D
class_name SoftBody
 

# Collections:
var particles:Array[Particle] = []
var constraints:Array = []


var submit_self:bool = false

@export_group("Debug")
@export var debug_particle_physics:bool = false


enum constraint {
    MAX_DISTANCE,       # two particles, one parameter
    MIN_DISTANCE,       # two particles, one parameter
    MIN_MAX_DISTANCE,   # two particles, two parameters
    EXACT_DISTANCE,     # two particles, one parameter
    MIN_ANGLE,          # three particles, one parameter,
    MIN_ANGLE_2,
    #ANGLE_RANGE,        # three particles, two parameters (Maybe not?)
    #JOINT,              # n particles, n
    POSITION,           # one particle, one parameter (Vector2)
    GLUE,               # two particles, zero parameters
    HANDLE              # one particle, zero parameters

}

func _ready():
    for child in get_children():
        if child is SoftBody:
            particles = particles + child.particles
            constraints = constraints + child.constraints
            child.constraints = []
    if submit_self:
        submit_soft_body()

func _draw():
    if debug_particle_physics:
        for p in particles:
            draw_line(p.position, p.position + 4*p.velocity, Color.BLUE, 3.)
            draw_line(p.position, p.position + p.gravity + p.external_force + p.impulse, Color.RED, 1.)

func _process(_delta):
    if debug_particle_physics:
        queue_redraw()


func add_soft_body(particles_, constraints_):
    var parent = get_parent()

    if parent is SoftBody:
        parent.add_soft_body(particles_, constraints_)
        return true
    else:
        particles = particles + particles_
        constraints = constraints + constraints_
        return false

func submit_soft_body():
    if add_soft_body(particles, constraints):
        constraints = []

# Expects a dictionary (for efficiency)
func annihilate_particles(particle_hash : Dictionary):
    var parent = get_parent()

    if parent is SoftBody:
        parent.annihilate_particles(particle_hash)
    else:
        # Recreate constraints
        var new_constraints = []
        for c in constraints:
            var flag = false
            for item in c:
                if particle_hash.has(item):
                    flag = true
                    break
            if flag: continue
            new_constraints.append(c)
        constraints = new_constraints

    var new_particles : Array[Particle] = []
    for p in particles:
        if not particle_hash.has(p):
            new_particles.append(p)
    particles = new_particles

func annihilate():
    # Make a set for constant lookup 
    var particle_hash = {}
    for p in particles:
        particle_hash[p] = true

    annihilate_particles(particle_hash)
    queue_free()



func glue_particles(P:Array):
    print("Gluing ",P.slice(1,len(P))," to ",P[0])
    for p in P.slice(1,len(P)):
        for C in constraints:
            for p0 in range(len(C)):
                if C[p0] is Particle and C[p0] == p: 
                    print("glued constraint ",C)
                    C[p0] = P[0]
    
        if len(constraints) > 0:
            while particles.has(p):
                particles.erase(p)
        else:
            for particle in range(len(particles)):
                if particles[particle] == p:
                    particles[particle] = P[0]
        
    for child in get_children():
        if child is SoftBody:
            child.glue_particles(P)

    #print(":")
    for p in P.slice(1,len(P)):
        p = null
        #print(p, p.get_reference_count())
        #if p.get_reference_count() ==0:
        #    p.free()






func add_n_particles(N:int, damp:float = 1, gravity:float = 0):
    for i in range(N):
        particles.append(Particle.new())
        particles[-1].damp = damp
        particles[-1].gravity = Vector2(0,gravity)

func add_constraint(C:Array):
    constraints.append(C)

"""func constraint_range(c:constraint):
    var constraint_map := {
        constraint.MAX_DISTANCE: 2,       # two particles, one parameter
        constraint.MIN_DISTANCE: 2,       # two particles, one parameter
        constraint.MIN_MAX_DISTANCE: 2,   # two particles, two parameters
        constraint.EXACT_DISTANCE: 2,     # two particles, one parameter
        constraint.MIN_ANGLE: 3,          # three particles, one parameter,
        constraint.MIN_ANGLE_: 3,          # three particles, one parameter,
        #constraint.ANGLE_RANGE: 3,
        constraint.POSITION: 1,           # one particle, one parameter (Vector2)
        constraint.GLUE: 0,               # two particles, zero parameters
        constraint.HANDLE: 1              # one particle, zero parameters
    }
    return range(1, 1 + constraint_map[c])"""
