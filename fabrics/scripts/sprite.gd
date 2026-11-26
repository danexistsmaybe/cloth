extends SoftBody



# Called when the node enters the scene tree for the first time.
func _ready():
    #super._ready()
    particles.append(Particle.new())
    particles[0].position = global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    $Sprite2D.global_position = particles[0].position
