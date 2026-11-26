extends SoftBody


func _ready():
    super._ready()

    for p in particles:
        if p.position.distance_to(global_position) < 1.0:
            add_constraint([constraint.HANDLE, p])
            
    
    #print(position)

func _physics_process(_delta):
    pass
