extends BlokParameter
class_name ParameterInput

@export var input_block : Node :
	set(node):
		if node != null:
			$MarginContainer/default_value.visible = false
			$input_block.visible = true
			$input_block.add_child(node)
		else:
			$MarginContainer/default_value.visible = true
			$input_block.visible = false
			$input_block.remove_child(input_block)
		input_block = node

func _setup() -> void:
	if attached:
		$MarginContainer.remove_theme_constant_override("margin_left")
	for default_value_display in $MarginContainer/default_value.get_children():
		if default_value_display.name == data_type:
			default_value_display.visible = true
		else:
			default_value_display.visible = false

func tentukan_parameter(parameter : Dictionary) -> void:
	print_debug(parameter)
	match parameter["type"]:
		"compare":			input_block = load("res://ui/blok kode/parameter_perbandingan.tscn").instantiate()
		"compare_variant":	input_block = load("res://ui/blok kode/parameter_perbandingan_tipe_data.tscn").instantiate()
		"and", "or":		input_block = load("res://ui/blok kode/parameter_logika.tscn").instantiate()
		"arithmetic":		input_block = load("res://ui/blok kode/parameter_aritmatika.tscn").instantiate()
	if input_block is BlokParameter:
		data_type = input_block.data_type
		input_block.tentukan_parameter(parameter)
	if input_block == null:
		match parameter["type"]:
			"bool":
				match parameter["value"]:
					"false":	$MarginContainer/default_value/bool.select(0)
					"true":		$MarginContainer/default_value/bool.select(1)
				$input_block.accept_type = "Boolean"
			"int":
				$MarginContainer/default_value/int.value = int(parameter["value"])
				$input_block.accept_type = "Number"
			"float":
				$MarginContainer/default_value/float.value = float(parameter["value"])
				$input_block.accept_type = "Number"
			"String":
				$MarginContainer/default_value/String.text = parameter["value"].substr(1, parameter["value"].length()-2)
				$input_block.accept_type = "String"
				_string_diubah()
		data_type = parameter["type"]

func hasilkan_kode() -> String:
	if input_block != null:
		return input_block.hasilkan_kode()
	else:
		match data_type:
			"bool":
				match $MarginContainer/default_value/bool.selected:
					0:	return "(false)"
					1:	return "(true)"
			"int":
				return str(int($MarginContainer/default_value/int.value))
			"float":
				return str($MarginContainer/default_value/float.value)
			"String":
				var result_text : String
				result_text = $MarginContainer/default_value/String.text.replace("\n", "\\n")
				result_text = result_text.replace("\t", "\\t")
				return "\"" + result_text + "\""
		return "null"

func _string_diubah() -> void:
	var jumlah_baris : int = $MarginContainer/default_value/String.get_line_count()
	var lebar_maks : float = 0.0
	
	for i in jumlah_baris:
		var lebar = $MarginContainer/default_value/String.get_line_width(i)
		if lebar > lebar_maks:
			lebar_maks = lebar
	
	custom_minimum_size.x = clamp(lebar_maks + 10, 100, 500)
