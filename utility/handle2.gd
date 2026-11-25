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
        textile.move_point([0,0], get_global_mouse_position()) 
        textile.move_point([0,textile.columns-1], get_global_mouse_position() + Vector2.LEFT*textile.columns*textile.max_distance_constraint) 
