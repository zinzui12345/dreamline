extends BlokParameter
class_name ParameterTeks

func tentukan_parameter(parameter : Dictionary) -> void:
	if parameter["type"] == "String":
		$MarginContainer/String.text = parameter["value"].substr(1, parameter["value"].length()-2)
		_string_diubah()

func hasilkan_kode() -> String:
	match data_type:
		"String":
			var result_text : String
			result_text = $MarginContainer/String.text.replace("\n", "\\n")
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
