extends StaticBody3D

func _input_event(_camera: Node, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			get_parent().emit_signal("pressed")
			$"../animation".stop()
			$"../animation".play("push")
