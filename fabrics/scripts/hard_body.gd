extends SoftBody


# Called when the node enters the scene tree for the first time.
func _ready():
    particles.append(Particle.new())
    particles[0].position = position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    $Hitbox.position = particles[0].position
