class_name Point
extends RefCounted 

var position:Vector2
var prev_position:Vector2
var velocity:Vector2
var anchored:bool
var anchor:Vector2

func _init():
    position = Vector2.ZERO
    prev_position = Vector2.ZERO
    velocity = Vector2.ZERO
    anchored = false
    anchor = Vector2.ZERO

func set_anchor(pos:Vector2):
    anchored = true
    anchor = pos
func rm_anchor():
    anchored = false

func set_prev_position():
    prev_position = position

func set_velocity():
    velocity = position - prev_position