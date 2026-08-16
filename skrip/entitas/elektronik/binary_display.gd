extends MeshInstance3D

func set_value(value : int = 1) -> void:
	if value == 1:
		$"1".visible = true
		$"0".visible = false
	elif value == 0:
		$"0".visible = true
		$"1".visible = false
	else:
		$"1".visible = false
		$"0".visible = false
