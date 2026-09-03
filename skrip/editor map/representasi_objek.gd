extends Node3D
class_name representasi_objek

@export var dapat_dipilih : bool = true :
	set(aktifkan_seleksi):
		$fisik_representasi/bentuk_fisik.disabled = !aktifkan_seleksi
		dapat_dipilih = aktifkan_seleksi
@export var jalur_instance : String :
	set(jalur_baru):
		for tmp_node in $instance_objek.get_children():
			tmp_node.queue_free()
		if jalur_baru != "" and ResourceLoader.exists(jalur_baru):
			var node_tampilan = load(jalur_baru).instantiate()
			node_tampilan.process_mode = PROCESS_MODE_DISABLED
			node_tampilan.mulai()
			$instance_objek.add_child(node_tampilan)
			if node_tampilan.get_node_or_null("bentuk") != null and node_tampilan.get_node("bentuk") is MeshInstance3D:
				var aabb_bentuk : AABB = node_tampilan.get_node("bentuk").get_aabb()
				node_tampilan.position = -(aabb_bentuk.size / 2) - aabb_bentuk.position
				ukuran = aabb_bentuk.size
			else:
				node_tampilan.position = -(node_tampilan.wilayah_render.size / 2) - node_tampilan.wilayah_render.position
				ukuran = node_tampilan.wilayah_render.size
			if node_tampilan.get("properti") != null:
				daftar_properti = node_tampilan.properti
			elif has_meta("setelan"):
				var _sp_properti : Array
				var dictionary_setelan : Dictionary = get_meta("setelan")
				for setelan in dictionary_setelan:
					if setelan == "ikon": continue
					_sp_properti.append([
						setelan,
						dictionary_setelan[setelan]
					])
				daftar_properti = _sp_properti
			jarak_render = node_tampilan.jarak_render
			$bentuk_kerangka.visible = true
			$tampilan_representasi.visible = false
		else:
			$bentuk_kerangka.visible = false
			$tampilan_representasi.visible = true
		jalur_instance = jalur_baru
@export var jarak_render : int = 10
@export var daftar_properti : Array
@export var ukuran : Vector3 = Vector3(1.0, 1.0, 1.0) :
	set(ukuran_baru):
		$fisik_representasi/bentuk_fisik.shape.size = ukuran_baru
		$bentuk_kerangka.mesh.size = ukuran_baru
		ukuran = ukuran_baru

func _ready() -> void:
	add_to_group("seleksi_aktif")
	
	var warna_random = Color.from_hsv(randf(), 0.8, randf_range(0.59, 1.0))
	$bentuk_kerangka.mesh = $bentuk_kerangka.mesh.duplicate()
	$bentuk_kerangka.mesh.material = $bentuk_kerangka.mesh.material.duplicate()
	$bentuk_kerangka.mesh.material.set_shader_parameter("wire_color", warna_random)
	
	$fisik_representasi/bentuk_fisik.shape = $fisik_representasi/bentuk_fisik.shape.duplicate()

func tampilkan_di_viewport(tampil : bool) -> void:
	if jalur_instance != "":
		$bentuk_kerangka.visible = tampil
	else:
		$tampilan_representasi.set_layer_mask_value(16, tampil)
		$tampilan_representasi.set_layer_mask_value(17, tampil)
		$tampilan_representasi.set_layer_mask_value(18, tampil)

func atur_properti(nama : String, nilai : Variant) -> void:
	for tmp_node in $instance_objek.get_children():
		if tmp_node.get(nama) != null:
			tmp_node.set(nama, nilai)

func _compile() -> Dictionary:
	return {
		"posisi":			global_position,
		"rotasi":			global_rotation_degrees,
		"jalur_instance":	jalur_instance,
		"jarak_render":		jarak_render,
		"daftar_properti":	daftar_properti
	}
