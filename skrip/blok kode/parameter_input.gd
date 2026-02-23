extends BlokParameter
class_name ParameterInput

@export var input_block : Node :
	set(node):
		if node != null:
			$MarginContainer/default_value.visible = false
			$MarginContainer/input_block.visible = true
			$MarginContainer/input_block.add_child(node)
		else:
			$MarginContainer/default_value.visible = true
			$MarginContainer/input_block.visible = false
			$MarginContainer/input_block.remove_child(input_block)
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
		"bool":		input_block = load("res://ui/blok kode/parameter_boolean.tscn").instantiate()
		"int":		input_block = load("res://ui/blok kode/parameter_angka.tscn").instantiate()
		"float":	input_block = load("res://ui/blok kode/parameter_angka_desimal.tscn").instantiate()
		#"String":					input_block = load("res://ui/blok kode/parameter_teks.tscn").instantiate()
	if input_block is BlokParameter:
		data_type = input_block.data_type
		input_block.tentukan_parameter(parameter)
func hasilkan_kode() -> String:
	if input_block != null:
		return input_block.hasilkan_kode()
	else:
		return "null"
