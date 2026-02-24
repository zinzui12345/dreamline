extends BlokParameter
class_name ParameterBoolean

func _setup() -> void:
	if attached:
		$MarginContainer.remove_theme_constant_override("margin_left")

func tentukan_parameter(parameter : Dictionary) -> void:
	if parameter["type"] == "bool":
		match parameter["value"]:
			"true":		$MarginContainer/boolean.select(1)
			"false":	$MarginContainer/boolean.select(0)
func hasilkan_kode() -> String:
	match $MarginContainer/boolean.selected:
		0:	return "(false)"
		1:	return "(true)"
	return ""
