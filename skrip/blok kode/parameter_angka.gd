extends BlokParameter
class_name ParameterAngka

func tentukan_parameter(parameter : Dictionary) -> void:
	$MarginContainer/number.value = parameter["value"]

func hasilkan_kode() -> String:
	return str($MarginContainer/number.value)
