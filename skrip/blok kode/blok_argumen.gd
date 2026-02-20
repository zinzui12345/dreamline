extends PanelContainer
class_name BlokArgumen

@export_enum("String", "Integer", "Float", "Object") var tipe_data : String = "String"

func atur(tipe : String, data : String) -> void:
	match tipe:
		"String":
			$String.visible = true
			$String.text = data
			_string_diubah()
	tipe_data = tipe

func _string_diubah() -> void:
	var jumlah_baris : int = $String.get_line_count()
	var lebar_maks : float = 0.0
	
	for i in jumlah_baris:
		var lebar = $String.get_line_width(i)
		if lebar > lebar_maks:
			lebar_maks = lebar
	
	custom_minimum_size.x = clamp(lebar_maks + 10, 100, 500)

func dapatkan_nilai() -> String:
	if tipe_data == "String":
		var result_text : String
		result_text = $String.text.replace("\n", "\\n")
		result_text = result_text.replace("\t", "\\t")
		return "\"" + result_text + "\""
	else:
		return ""
