extends SoftBody


func _ready():
    super._ready()

    for p in particles:
        if p.position == global_position:
            add_constraint([constraint.HANDLE, p])
            
    
    #print(position)

func _physics_process(_delta):
    pass
