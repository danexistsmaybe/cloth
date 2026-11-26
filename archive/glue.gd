extends Line2D

# DEPRECATED

"""# Collections:
@export var particles:Array[Particle]
@export var constraints:Array = []

var constraint_map := {
    Particle.constraint.MAX_DISTANCE: 2,       # two particles, one parameter
    Particle.constraint.MIN_DISTANCE: 2,       # two particles, one parameter
    Particle.constraint.MIN_MAX_DISTANCE: 2,   # two particles, two parameters
    Particle.constraint.EXACT_DISTANCE: 2,     # two particles, one parameter
    Particle.constraint.MIN_ANGLE: 3,          # three particles, one parameter
    Particle.constraint.POSITION: 1,           # one particle, one parameter (Vector2)
    Particle.constraint.GLUE: 0,               # two particles, zero parameters
    Particle.constraint.HANDLE: 1              # one particle, zero parameters
}
 

func _ready():
    for child in get_children():
        particles = particles + child.particles
        constraints = constraints + child.constraints
        child.constraints = []
    
    # Assign glue constraints based on particles that share the positions of the points in the line2d
    var glue_constraints:Array = []
    for point in points:
        var to_glue:Array[Particle] = []

        # Collect all particles that share a position with this point
        for particle in particles:
            if particle.position == point: to_glue.append(particle)
        
        # If there is more than one particle we can glue them
        if len(to_glue) > 1:
            for particle in to_glue.slice(1,len(to_glue)):
                # Find every time the second particle comes up in a constraint and replace it with the first
                for constraint in constraints:
                    for p in range(1, 1 + constraint_map[constraint[0]]):
                        if constraint[p] == particle: 
                            constraint[p] = to_glue[0]
                            constraint[p].copy_parameters_from(particle)
                # Keep track of what particles have been glued so we can continue updating them for rendering purposes
                glue_constraints.append([Particle.constraint.GLUE, to_glue[0], particle]) 
    print(glue_constraints)
    constraints = constraints + glue_constraints

"""