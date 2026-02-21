extends VBoxContainer
class_name AreaBlokKode

const EditorKode = preload("res://skrip/blok kode/editor_kode.gd")

func _can_drop_data(_at_position, data):
	if data is BlokKode:
		if data.use_once and data.code in EditorKode.dapatkan_daftar_kode():
			return false
		elif !(data.block_type in ["Fungsi", "Variabel"]):
			return false
		else:
			return true
	return true

func _drop_data(_at_position, data):
	if data is BlokKode:
		add_child(data)
		data.block_id = EditorKode.tambah_kode(data.code)
