extends PanelContainer
class_name BlokParameter

@export var locked : bool = false
@export var attached : bool = false

@export_enum("bool", "int", "float", "String", "Array", "Dictionary", "Object", "Variant") var data_type = "bool"

const EditorKode = preload("res://skrip/blok kode/editor_kode.gd")

func tentukan_parameter(parameter : Dictionary) -> void:
	print(parameter)

func hasilkan_kode() -> String:
	return ""

# 1. Mulai Dragging
func _get_drag_data(_at_position):
	if locked or attached: return null
	
	var preview = self.duplicate()
	set_drag_preview(preview)
	
	# Kita return "self" (node ini) sebagai data yang dibawa
	if get_parent() is DaftarBlokKode:
		return self.duplicate()
	else:
		return self

# 2. Cek apakah bisa didrop di sini
func _can_drop_data(_at_position, data):
	if locked: return false
	if data is BlokParameter and data != self and data.data_type == data_type:
		return true
	return false
