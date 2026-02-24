extends BlokParameter
class_name ParameterAngka

func tentukan_parameter(parameter : Dictionary) -> void:
	match data_type:
		"int":		$MarginContainer/number.value = int(parameter["value"])
		"float":	$MarginContainer/number.value = parameter["value"]

func hasilkan_kode() -> String:
	match data_type:
		"int":		return str(int($MarginContainer/number.value))
		"float":	return str($MarginContainer/number.value)
	return str($MarginContainer/number.value)
