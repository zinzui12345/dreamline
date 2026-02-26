extends BlokParameter
class_name ParameterPerbandinganTipeData

@export var left_block : Node :
	set(node):
		if $MarginContainer/compare_operator/left_block.get_child_count() == 1 and node != null:
			left_block = $MarginContainer/compare_operator/left_block.get_child(0)
		else:
			if node != null:
				$MarginContainer/compare_operator/left_block.add_child(node)
			else:
				$MarginContainer/compare_operator/left_block.remove_child(left_block)
			left_block = node
@export var right_block : Node :
	set(node):
		if $MarginContainer/compare_operator/right_block.get_child_count() == 1 and node != null:
			right_block = $MarginContainer/compare_operator/right_block.get_child(0)
		else:
			if right_block != node:
				if node != null:
					$MarginContainer/compare_operator/right_block.add_child(node)
				else:
					$MarginContainer/compare_operator/right_block.remove_child(right_block)
				right_block = node

func tentukan_parameter(parameter : Dictionary) -> void:
	match parameter["left"]["type"]:
		"int":
			left_block = load("res://ui/blok kode/parameter_angka.tscn").instantiate()
		"float":
			left_block = load("res://ui/blok kode/parameter_angka_desimal.tscn").instantiate()
		"String":
			left_block = load("res://ui/blok kode/parameter_teks.tscn").instantiate()
		"bool":
			left_block = load("res://ui/blok kode/parameter_boolean.tscn").instantiate()
		"compare":
			left_block = load("res://ui/blok kode/parameter_perbandingan.tscn").instantiate()
		"and", "or":
			left_block = load("res://ui/blok kode/parameter_logika.tscn").instantiate()
		"arithmetic":
			left_block = load("res://ui/blok kode/parameter_aritmatika.tscn").instantiate()
	if left_block is BlokParameter:
		left_block.tentukan_parameter(parameter["left"])
	match parameter["operator"]:
		"==":	$MarginContainer/compare_operator/operator.select(0)
		"!=":	$MarginContainer/compare_operator/operator.select(1)
	match parameter["right"]["type"]:
		"int":
			right_block = load("res://ui/blok kode/parameter_angka.tscn").instantiate()
		"float":
			right_block = load("res://ui/blok kode/parameter_angka_desimal.tscn").instantiate()
		"String":
			right_block = load("res://ui/blok kode/parameter_teks.tscn").instantiate()
		"bool":
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
	match $MarginContainer/compare_operator/operator.selected:
		0: result += " == "
		1: result += " != "
	if right_block != null and right_block is BlokParameter:
		result += right_block.hasilkan_kode()
	result += ")"
	return result
