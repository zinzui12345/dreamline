extends Node3D
class_name kode_ubahan

@export var kode : String = "func gunakan():\n\tPanku.notify(\"ini adalah contoh kode\")"

# FIXME : sinkronkan kondisi ketika memanggil fungsi

func _ready(): atur_kode(kode)

func dapatkan_kode() -> String:
	return kode

func atur_kode(_kode : String):
	# compile _kode ke komponen GDScript
	var eksekusi := GDScript.new()
	eksekusi.source_code = "extends Node\n\n" + _kode
	var galat := eksekusi.reload()
	
	# debug hasil compiler
	print_debug("hasil compile: \n"+_kode)
	print_debug(galat)
	
	# cek hasil
	if galat == OK:
		$compiler.set_script(eksekusi)
	else:
		Panku.notify("kode tidak valid!")
	
	# atur nilai
	kode = _kode
	if get_parent().kode != _kode: get_parent().kode = _kode

func panggil_fungsi_kode(nama_fungsi : String, id_pengguna):
	if $compiler.has_method(nama_fungsi):
		$compiler.call(nama_fungsi)
