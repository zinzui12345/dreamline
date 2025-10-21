extends Node3D

@export var follow : Wheel
@export var target : Node3D
@export_group("Follow Position")
@export var position_y : bool
@export var position_z : bool
@export_group("Follow Rotation")
@export var rotation_x : bool
@export var rotation_y : bool

func _process(_delta: float) -> void:
	if position_y:	target.position.y = follow.wheel_node.position.y
	if position_z:	position.z = follow.position.z
	
	if rotation_x:	target.rotation.x = follow.wheel_node.rotation.x
	if rotation_y:	rotation.y = follow.rotation.y
