extends Node3D

@export var dapat_dipilih : bool = true :
	set(aktifkan_seleksi):
		$fisik_representasi/bentuk_fisik.disabled = !aktifkan_seleksi
		dapat_dipilih = aktifkan_seleksi
@export var jalur_instance : String
@export var daftar_properti : Dictionary
@export var ukuran : Vector3 = Vector3(1.0, 1.0, 1.0) :
	set(ukuran_baru):
		#$fisik/bentuk_fisik.shape.size = ukuran_baru
		#$bentuk_kerangka.mesh.size = ukuran_baru
		
		ukuran = ukuran_baru

func _ready() -> void:
	add_to_group("seleksi_aktif")

func tampilkan_di_viewport(tampil : bool) -> void:
	$tampilan_representasi.set_layer_mask_value(16, tampil)
	$tampilan_representasi.set_layer_mask_value(17, tampil)
	$tampilan_representasi.set_layer_mask_value(18, tampil)

func _compile() -> Dictionary:
	"""
		return {
			"posisi":	global_position,
			"rotasi":	global_rotation_degrees,
			"jalur_instance":	mesh_gabungan_instance,
			"properti":	$fisik/bentuk_fisik.duplicate()
		}
	"""
	return {}
