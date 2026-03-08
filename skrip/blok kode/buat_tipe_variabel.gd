extends OptionButton

@export var blok_kode : BlokKode

const EditorKode = preload("res://skrip/blok kode/editor_kode.gd")

func atur_tipe(tipe : String) -> void:
	match tipe:
		"bool":			select(0)
		"int":			select(1)
		"float":		select(2)
		"String":		select(3)
		"Array":		select(4)
		"Dictionary":	select(5)

func dapatkan_tipe() -> String:
	match selected:
		0:	return "bool"
		1:	return "int"
		2:	return "float"
		3:	return "String"
		4:	return "Array"
		5:	return "Dictionary"
		_: 	return "Variant"

func tipe_diubah(_tipe_dipilih : int) -> void:
	EditorKode.ubah_tipe_variabel(blok_kode.var_id, dapatkan_tipe())
