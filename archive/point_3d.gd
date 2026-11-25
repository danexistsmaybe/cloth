class_name Point3D
extends RefCounted 

var position:Vector3
var prev_position:Vector3
var velocity:Vector3
var anchored:bool
var anchor:Vector3

func _init():
    position = Vector3.ZERO
    prev_position = Vector3.ZERO
    velocity = Vector3.ZERO
    anchored = false
    anchor = Vector3.ZERO

func set_anchor(pos:Vector3):
    anchored = true
    anchor = pos
func rm_anchor():
    anchored = false
