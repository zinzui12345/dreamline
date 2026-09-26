extends Button

@export var id : int = -1

var pointer_map_editor : Control

func atur(pemicu : String, node_tujuan : String, metode : String, parameter : String, map_editor : Control) -> void:
	$daftar_nilai/pemicu.text = pemicu
	$daftar_nilai/node_tujuan.text = node_tujuan
	$daftar_nilai/metode.text = metode + "()"
	$daftar_nilai/parameter_metode.text = parameter
	pointer_map_editor = map_editor

func dapatkan_nilai() -> Array:
	return [
		$daftar_nilai/pemicu.text,
		$daftar_nilai/node_tujuan.text,
		$daftar_nilai/metode.text,
		$daftar_nilai/parameter_metode.text
	]

func sesuaikan_tampilan_pilihan() -> void:
	$daftar_nilai/pilih.visible = button_pressed
	$daftar_nilai/pemisah_horizontal.visible = button_pressed

func _ketika_pilih() -> void:
	sesuaikan_tampilan_pilihan()
	if pointer_map_editor != null:
		if button_pressed:
			pointer_map_editor._ketika_memilih_sinyal_objek(id)
		else:
			pointer_map_editor._ketika_berhenti_memilih_sinyal_objek()
