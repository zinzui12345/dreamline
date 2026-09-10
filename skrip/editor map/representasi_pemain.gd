extends Node3D
class_name representasi_pemain

@export var dapat_dipilih : bool = true :
	set(aktifkan_seleksi):
		$fisik_representasi/bentuk_fisik.disabled = !aktifkan_seleksi
		dapat_dipilih = aktifkan_seleksi
@export var ukuran : Vector3 = Vector3(1.0, 1.0, 1.0) 

func _ready() -> void:
	add_to_group("seleksi_aktif")
	
	var warna_random = Color.from_hsv(randf(), 0.8, randf_range(0.59, 1.0))
	$bentuk_kerangka.mesh = $bentuk_kerangka.mesh.duplicate()
	$bentuk_kerangka.mesh.material = $bentuk_kerangka.mesh.material.duplicate()
	$bentuk_kerangka.mesh.material.set_shader_parameter("wire_color", warna_random)
	
	ukuran = $fisik_representasi/bentuk_fisik.shape.size
	
	$fisik_representasi/bentuk_fisik.shape = $fisik_representasi/bentuk_fisik.shape.duplicate()

func tampilkan_di_viewport(tampil : bool) -> void:
	$bentuk_kerangka.visible = tampil

func atur_rotasi(arah : float) -> void: $model_pemain.global_rotation_degrees.y = arah
func dapatkan_rotasi() -> float: return $model_pemain.global_rotation_degrees.y

func _compile() -> Dictionary:
	return {
		"posisi":	$model_pemain.global_position,
		"rotasi":	$model_pemain.global_rotation
	}
