extends Node2D

var t := 0.

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

func _physics_process(delta):
    if Input.is_action_just_pressed("dither"):
        #print("D")
        $dither.visible = !$dither.visible
    
    $dither.material.set_shader_parameter("dither_color", Color.from_hsv(fmod(t,10.)/10., 1.0, 1.0))
    t += delta
