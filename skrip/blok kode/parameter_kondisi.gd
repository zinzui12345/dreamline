extends BlokParameter
class_name ParameterKondisi

@export_enum("identifier", "compare", "arithmetic", "and", "or") var operator_type = "identifier":
	set(type):
		match type:
			"identifier":
				$boolean.visible = true
				$boolean.disabled = false
				$input_block.visible = false
				$input_operator.visible = false
				$input_operator/compare_operator.visible = false
				$input_operator/arithmetic_operator.visible = false
				$input_operator/boolean_operator.visible = false
			"compare":
				$boolean.visible = false
				$boolean.disabled = true
				$input_block.visible = false
				$input_operator.visible = true
				$input_operator/compare_operator.visible = true
				$input_operator/arithmetic_operator.visible = false
				$input_operator/boolean_operator.visible = false
			"arithmetic":
				$boolean.visible = false
				$boolean.disabled = true
				$input_block.visible = false
				$input_operator.visible = true
				$input_operator/compare_operator.visible = false
				$input_operator/arithmetic_operator.visible = true
				$input_operator/boolean_operator.visible = false
			"and", "or":
				$boolean.visible = false
				$boolean.disabled = true
				$input_block.visible = false
				$input_operator.visible = true
				$input_operator/compare_operator.visible = false
				$input_operator/arithmetic_operator.visible = false
				$input_operator/boolean_operator.visible = true
		operator_type = type
@export var left_block : Node
@export var right_block : Node
@export var input_block : Node

#const input_block_min_width = 80

func tentukan_parameter(parameter : Dictionary) -> void:
	print(parameter)
	# { "type": "identifier", "value": "true" }
	# { "type": "compare", "operator": ">", "left": { "type": "number", "value": 0.0 }, "right": { "type": "number", "value": 1.0 } }
	# { "type": "and", "left": { "type": "compare", "operator": ">", "left": { "type": "number", "value": 0.0 }, "right": { "type": "number", "value": 1.0 } }, "right": { "type": "compare", "operator": ">", "left": { "type": "number", "value": 1.0 }, "right": { "type": "number", "value": 3.0 } } }
	# { "type": "or", "left": { "type": "compare", "operator": ">", "left": { "type": "number", "value": 0.0 }, "right": { "type": "number", "value": 1.0 } }, "right": { "type": "compare", "operator": ">", "left": { "type": "number", "value": 1.0 }, "right": { "type": "number", "value": 3.0 } } }
	operator_type = parameter["type"]
	match operator_type:
		"identifier":
			match parameter["value"]:
				"true":		$boolean.select(1)
				"false":	$boolean.select(0)
		"compare":
			match parameter["left"]["type"]:
				"number":
					left_block = load("res://ui/blok kode/parameter_angka.tscn").instantiate()
					$input_operator/compare_operator/left_block.add_child(left_block)
					left_block.tentukan_parameter(parameter["left"])
				"identifier", "compare", "and", "or":
					left_block = self.duplicate()
					left_block.attached = false
					$input_operator/compare_operator/left_block.add_child(left_block)
					left_block.tentukan_parameter(parameter["left"])
					#_atur_lebar_area_input_kiri($input_operator/compare_operator/left_block.size.x)
			match parameter["operator"]:
				"<":	$input_operator/compare_operator/operator.select(0)
				">":	$input_operator/compare_operator/operator.select(1)
				"<=":	$input_operator/compare_operator/operator.select(2)
				">=":	$input_operator/compare_operator/operator.select(3)
				"==":	$input_operator/compare_operator/operator.select(4)
				"!=":	$input_operator/compare_operator/operator.select(5)
			match parameter["right"]["type"]:
				"number":
					right_block = load("res://ui/blok kode/parameter_angka.tscn").instantiate()
					$input_operator/compare_operator/right_block.add_child(right_block)
					right_block.tentukan_parameter(parameter["right"])
				"identifier", "compare", "and", "or":
					right_block = self.duplicate()
					right_block.attached = false
					$input_operator/compare_operator/right_block.add_child(right_block)
					right_block.tentukan_parameter(parameter["right"])
					#_atur_lebar_area_input_kanan($input_operator/compare_operator/right_block.size.x)
		"and", "or":
			match parameter["left"]["type"]:
				"number":
					left_block = load("res://ui/blok kode/parameter_angka.tscn").instantiate()
					$input_operator/boolean_operator/left_block.add_child(left_block)
					left_block.tentukan_parameter(parameter["left"])
				"identifier", "compare", "and", "or":
					left_block = self.duplicate()
					left_block.attached = false
					$input_operator/boolean_operator/left_block.add_child(left_block)
					left_block.tentukan_parameter(parameter["left"])
					#_atur_lebar_area_input_kiri($input_operator/boolean_operator/left_block.size.x)
			match parameter["type"]:
				"and":	$input_operator/boolean_operator/operator.select(0)
				"or":	$input_operator/boolean_operator/operator.select(1)
			match parameter["right"]["type"]:
				"number":
					right_block = load("res://ui/blok kode/parameter_angka.tscn").instantiate()
					$input_operator/compare_operator/right_block.add_child(right_block)
					right_block.tentukan_parameter(parameter["right"])
				"identifier", "compare", "and", "or":
					right_block = self.duplicate()
					right_block.attached = false
					$input_operator/boolean_operator/right_block.add_child(right_block)
					right_block.tentukan_parameter(parameter["right"])
					#_atur_lebar_area_input_kanan($input_operator/boolean_operator/right_block.size.x)

func hasilkan_kode() -> String:
	match operator_type:
		"identifier":
			match $boolean.selected:
				0:	return "(false)"
				1:	return "(true)"
		"compare":
			var result : String = "("
			if left_block != null and left_block is BlokParameter:
				result += left_block.hasilkan_kode()
			match $input_operator/compare_operator/operator.selected:
				0: result += " < "
				1: result += " > "
				2: result += " <= "
				3: result += " >= "
				4: result += " == "
				5: result += " != "
			if right_block != null and right_block is BlokParameter:
				result += right_block.hasilkan_kode()
			result += ")"
			return result
		"and", "or":
			var result : String = "("
			if left_block != null and left_block is BlokParameter:
				result += left_block.hasilkan_kode()
			match $input_operator/boolean_operator/operator.selected:
				0: result += " and "
				1: result += " or "
			if right_block != null and right_block is BlokParameter:
				result += right_block.hasilkan_kode()
			result += ")"
			return result
	return ""

#func _atur_lebar_area_input_kiri(lebar_px) -> void:
	#$input_operator/compare_operator/left_block.custom_minimum_size.x = lebar_px
	#$input_operator/arithmetic_operator/left_block.custom_minimum_size.x = lebar_px
	#$input_operator/boolean_operator/left_block.custom_minimum_size.x = lebar_px
#func _atur_lebar_area_input_kanan(lebar_px) -> void:
	#$input_operator/compare_operator/right_block.custom_minimum_size.x = lebar_px
	#$input_operator/arithmetic_operator/right_block.custom_minimum_size.x = lebar_px
	#$input_operator/boolean_operator/right_block.custom_minimum_size.x = lebar_px
