extends BlokParameter
class_name ParameterBoolean

@export var input_block : Node :
	set(node):
		if node != null:
			$MarginContainer/boolean.visible = false
			$MarginContainer/input_block.visible = true
			$MarginContainer/input_block.add_child(node)
		else:
			$MarginContainer/boolean.visible = true
			$MarginContainer/input_block.visible = false
			$MarginContainer/input_block.remove_child(input_block)
		input_block = node

func _setup() -> void:
	if attached:
		$MarginContainer.remove_theme_constant_override("margin_left")

func tentukan_parameter(parameter : Dictionary) -> void:
	print(parameter)
	match parameter["type"]:
		"identifier":
			match parameter["value"]:
				"true":		$MarginContainer/boolean.select(1)
				"false":	$MarginContainer/boolean.select(0)
		"compare":
			input_block = load("res://ui/blok kode/parameter_perbandingan.tscn").instantiate()
		"and", "or":
			input_block = load("res://ui/blok kode/parameter_logika.tscn").instantiate()
		"arithmetic":
			input_block = load("res://ui/blok kode/parameter_aritmatika.tscn").instantiate()
	if input_block is BlokParameter:
		input_block.tentukan_parameter(parameter)
func hasilkan_kode() -> String:
	if input_block != null:
		return input_block.hasilkan_kode()
	else:
		match $MarginContainer/boolean.selected:
			0:	return "(false)"
			1:	return "(true)"
	return ""
