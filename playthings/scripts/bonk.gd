extends SoftBody


# Called when the node enters the scene tree for the first time.
func _ready():
    super._ready()

    for P in particles:
        P.gravity = Vector2(0,1)
        P.collision = true
        P.collision_mask = 0b0111


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass
