extends BlokParameter
class_name ParameterLogika

@export var left_block : Node :
	set(node):
		if node != null:
			$MarginContainer/logic_operator/left_block.add_child(node)
		else:
			$MarginContainer/logic_operator/left_block.remove_child(left_block)
		left_block = node
@export var right_block : Node :
	set(node):
		if node != null:
			$MarginContainer/logic_operator/right_block.add_child(node)
		else:
			$MarginContainer/logic_operator/right_block.remove_child(right_block)
		right_block = node

func tentukan_parameter(parameter : Dictionary) -> void:
	match parameter["left"]["type"]:
		"number":
			left_block = load("res://ui/blok kode/parameter_angka.tscn").instantiate()
		"identifier":
			left_block = load("res://ui/blok kode/parameter_boolean.tscn").instantiate()
		"compare":
			left_block = load("res://ui/blok kode/parameter_perbandingan.tscn").instantiate()
		"and", "or":
			left_block = load("res://ui/blok kode/parameter_logika.tscn").instantiate()
		"arithmetic":
			left_block = load("res://ui/blok kode/parameter_aritmatika.tscn").instantiate()
	if left_block is BlokParameter:
		left_block.tentukan_parameter(parameter["left"])
	match parameter["type"]:
		"and":	$MarginContainer/logic_operator/operator.select(0)
		"or":	$MarginContainer/logic_operator/operator.select(1)
	match parameter["right"]["type"]:
		"number":
			right_block = load("res://ui/blok kode/parameter_angka.tscn").instantiate()
		"identifier":
			right_block = load("res://ui/blok kode/parameter_boolean.tscn").instantiate()
		"compare":
			right_block = load("res://ui/blok kode/parameter_perbandingan.tscn").instantiate()
		"and", "or":
			right_block = load("res://ui/blok kode/parameter_logika.tscn").instantiate()
		"arithmetic":
			right_block = load("res://ui/blok kode/parameter_aritmatika.tscn").instantiate()
	if right_block is BlokParameter:
		right_block.tentukan_parameter(parameter["right"])

func hasilkan_kode() -> String:
	var result : String = "("
	if left_block != null and left_block is BlokParameter:
		result += left_block.hasilkan_kode()
	match $MarginContainer/logic_operator/operator.selected:
		0: result += " and "
		1: result += " or "
	if right_block != null and right_block is BlokParameter:
		result += right_block.hasilkan_kode()
	result += ")"
	return result
