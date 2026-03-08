extends LineEdit

@export var blok_kode : BlokKode

const EditorKode = preload("res://skrip/blok kode/editor_kode.gd")

func nama_diubah(nama_baru : String) -> void:
	custom_minimum_size.x = clamp((nama_baru.length() * 10) + 10, 68.5, 500)
	# TODO : fix nama duplikat
	# FIXME : cegah karakter tak valid
	EditorKode.ubah_nama_variabel(blok_kode.var_id, nama_baru)
