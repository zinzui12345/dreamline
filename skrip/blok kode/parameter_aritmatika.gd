extends BlokParameter
class_name ParameterAritmatika

@export var left_block : Node :
	set(node):
		if $MarginContainer/arithmetic_operator/left_value/left_block.get_child_count() == 1 and node != null:
			left_block = $MarginContainer/arithmetic_operator/left_value/left_block.get_child(0)
			$MarginContainer/arithmetic_operator/left_value/left_default_value.visible = false
		else:
			if node != null:
				$MarginContainer/arithmetic_operator/left_value/left_block.add_child(node)
				$MarginContainer/arithmetic_operator/left_value/left_block.visible = true
				$MarginContainer/arithmetic_operator/left_value/left_default_value.visible = false
			else:
				if left_block != null:
					$MarginContainer/arithmetic_operator/left_value/left_block.remove_child(left_block)
				$MarginContainer/arithmetic_operator/left_value/left_block.visible = false
				$MarginContainer/arithmetic_operator/left_value/left_default_value.visible = true
			left_block = node
@export var right_block : Node :
	set(node):
		if $MarginContainer/arithmetic_operator/right_value/right_block.get_child_count() == 1 and node != null:
			right_block = $MarginContainer/arithmetic_operator/right_value/right_block.get_child(0)
			$MarginContainer/arithmetic_operator/right_value/right_default_value.visible = false
		else:
			if node != null:
				$MarginContainer/arithmetic_operator/right_value/right_block.add_child(node)
				$MarginContainer/arithmetic_operator/right_value/right_block.visible = true
				$MarginContainer/arithmetic_operator/right_value/right_default_value.visible = false
			else:
				if right_block != null:
					$MarginContainer/arithmetic_operator/right_value/right_block.remove_child(right_block)
				$MarginContainer/arithmetic_operator/right_value/right_block.visible = false
				$MarginContainer/arithmetic_operator/right_value/right_default_value.visible = true
			right_block = node

func tentukan_parameter(parameter : Dictionary) -> void:
	match parameter["left"]["type"]:
		"int":
			$MarginContainer/arithmetic_operator/left_value/left_default_value.value = int(parameter["left"]["value"])
		"float":
			left_block = load("res://ui/blok kode/parameter_angka_desimal.tscn").instantiate()
		"arithmetic":
			left_block = load("res://ui/blok kode/parameter_aritmatika.tscn").instantiate()
	if left_block is BlokParameter:
		left_block.tentukan_parameter(parameter["left"])
	match parameter["operator"]:
		"+":	$MarginContainer/arithmetic_operator/operator.select(0)
		"-":	$MarginContainer/arithmetic_operator/operator.select(1)
		"*":	$MarginContainer/arithmetic_operator/operator.select(2)
		"/":	$MarginContainer/arithmetic_operator/operator.select(3)
		"%":	$MarginContainer/arithmetic_operator/operator.select(4)
	match parameter["right"]["type"]:
		"int":
			$MarginContainer/arithmetic_operator/right_value/right_default_value.value = int(parameter["right"]["value"])
		"float":
			right_block = load("res://ui/blok kode/parameter_angka_desimal.tscn").instantiate()
		"arithmetic":
			right_block = load("res://ui/blok kode/parameter_aritmatika.tscn").instantiate()
	if right_block is BlokParameter:
		right_block.tentukan_parameter(parameter["right"])

func hasilkan_kode() -> String:
	var result : String = "("
	if left_block != null and left_block is BlokParameter:
		result += left_block.hasilkan_kode()
	else:
		result += str(int($MarginContainer/arithmetic_operator/left_value/left_default_value.value))
	match $MarginContainer/arithmetic_operator/operator.selected:
		0: result += " + "
		1: result += " - "
		2: result += " * "
		3: result += " / "
		4: result += " % "
	if right_block != null and right_block is BlokParameter:
		result += right_block.hasilkan_kode()
	else:
		result += str(int($MarginContainer/arithmetic_operator/right_value/right_default_value.value))
	result += ")"
	return result
