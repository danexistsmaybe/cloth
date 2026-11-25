extends Node2D

@export var p = 0

var textile : Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
    textile = get_children()[0]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
    pass

func _physics_process(_delta):
    if Input.is_action_pressed("mouse_down"):
        textile.move_point(textile.get_first_point(), get_global_mouse_position()) 
