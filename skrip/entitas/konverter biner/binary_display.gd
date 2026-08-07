extends MeshInstance3D

func set_value(value : int = 1) -> void:
	if value == 1:
		$off/A.visible = true
		$off/B.visible = false
		$off/C.visible = true
		$off/D.visible = true
		$A.visible = false
		$B.visible = true
		$C.visible = false
		$D.visible = false
	elif value == 0:
		$off/A.visible = false
		$off/B.visible = false
		$off/C.visible = false
		$off/D.visible = false
		$A.visible = true
		$B.visible = true
		$C.visible = true
		$D.visible = true
	else:
		$off/A.visible = true
		$off/B.visible = true
		$off/C.visible = true
		$off/D.visible = true
		$A.visible = false
		$B.visible = false
		$C.visible = false
		$D.visible = false
