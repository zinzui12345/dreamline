extends BlokParameter
class_name ParameterAngka

func tentukan_parameter(parameter : Dictionary) -> void:
	$number.value = parameter["value"]

func hasilkan_kode() -> String:
	return str($number.value)
