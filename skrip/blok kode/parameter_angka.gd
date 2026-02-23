extends BlokParameter
class_name ParameterAngka

func tentukan_parameter(parameter : Dictionary) -> void:
	match data_type:
		"Integer":	$MarginContainer/number.value = int(parameter["value"])
		"Float":	$MarginContainer/number.value = parameter["value"]

func hasilkan_kode() -> String:
	match data_type:
		"Integer":	return str(int($MarginContainer/number.value))
		"Float":	return str($MarginContainer/number.value)
	return str($MarginContainer/number.value)
