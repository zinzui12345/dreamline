extends Control
class_name BlokArgumen

@export_enum("String", "Integer", "Float", "Object") var tipe_data : String = "String"

func atur(tipe : String, data : String) -> void:
	match tipe:
		"String":
			$String.visible = true
			$String.text = data
	tipe_data = tipe

func _string_diubah() -> void:
	var jumlah_baris = $String.get_line_count()
	if jumlah_baris <= 1:
		custom_minimum_size.y = 32
	else:
		custom_minimum_size.y = 32 * jumlah_baris

func dapatkan_nilai() -> String:
	if tipe_data == "String":
		var result_text : String
		result_text = $String.text.replace("\n", "\\n")
		result_text = result_text.replace("\t", "\\t")
		return "\"" + result_text + "\""
	else:
		return ""
