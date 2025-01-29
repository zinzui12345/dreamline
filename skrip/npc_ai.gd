# 03/11/23
extends CharacterBody3D

class_name npc_ai

# TODO : hanya proses navigasi pada peer pemroses

var navigasi : NavigationAgent3D
var _proses_navigasi : bool = false
var id_proses : int = -1:					# id peer/pemain yang memproses npc ini
	set(id):
		atur_pemroses(id)
		id_proses = id
var id_pengubah : int = -1:					# id peer/pemain yang mengubah npc ini
	set(id):
		if id == client.id_koneksi:
			set_process(true)
		else:
			set_process(false)
		id_pengubah = id
var cek_properti : Dictionary = {}			# simpan beberapa properti di tiap frame untuk membandingkan perubahan

enum grup {
	pemain,		# + teman, mis: hewan 
	netral,		# = hewan liar
	musuh		# - monster
}

@export var jalur_skena : StringName = "res://skena/npc_ai.tscn"
@export var nyawa : int = 100
@export var serangan : int = 25
@export var kelompok := grup.netral
@export var kecepatan_gerak : float = 2

@export var wilayah_render : AABB :					# area batas culling
	set(aabb):
		if is_inside_tree():
			var tmp_aabb : Array = []
			for titik in 8:
				# terapkan posisi titik AABB ke array
				tmp_aabb.append(aabb.get_endpoint(titik))
			titik_sudut = tmp_aabb
		wilayah_render = aabb
@export var jarak_render : int = 50					# jarak maks render
@export var radius_keterlihatan : int = 50			# jarak batas frustum culling
@export var titik_sudut : Array = []				# titik tiap sudut AABB untuk occlusion culling
@export var cek_titik : int = 0						# simpan titik terakhir occlusion culling
@export var tak_terlihat : bool = false				# simpan kondisi frustum culling
@export var terhalang : bool = false				# simpan kondisi occlusion culling
@export var kode : BlockScriptSerialization :		# jika menggunakan kode ubahan
	set(kode_baru):
		if get_node_or_null("kode_ubahan") != null and get_node("kode_ubahan") is BlockCode:
			if $kode_ubahan.block_script != kode_baru:
				cek_properti["kode"] = kode_baru.generated_script
				$kode_ubahan.block_script = kode_baru
				$kode_ubahan._update_parent_script()
			kode = kode_baru

## setup ##
func _ready() -> void:
	if get_parent().get_path() != dunia.get_node("karakter").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and (not server.mode_replay or server.mode_uji_performa):
			var _sp_properti : Array	# array berisi properti kustom dengan nilai yang telah diubah pada karakter | ini digunakan untuk menambahkan karakter ke server
			if get("properti") != null:
				for properti_kustom : Array in get("properti"):
					_sp_properti.append([
						properti_kustom[0],
						get(properti_kustom[0])
					])
				if get_node_or_null("kode_ubahan") != null and get_node("kode_ubahan") is BlockCode:
					_sp_properti.append([
						"kode",
						$kode_ubahan.block_script
					])
			elif has_meta("setelan"):
				var dictionary_setelan : Dictionary = get_meta("setelan")
				for setelan in dictionary_setelan:
					if setelan == "ikon": continue
					_sp_properti.append([
						setelan,
						dictionary_setelan[setelan]
					])
			else:
				push_error("[Galat] npc %s tidak memiliki properti!" % name)
			var _jalur_instance : String
			if get("jalur_skena") == "":
				_jalur_instance = get("jalur_instance")
			else:
				push_error("[Galat] npc %s tidak memiliki jalur skena!" % name)
			
			server._tambahkan_karakter(
				jalur_skena,
				global_transform.origin,
				rotation,
				_sp_properti
			)
		queue_free()
	else:
		navigasi = $navigasi
		navigasi.avoidance_enabled = true
		navigasi.connect("velocity_computed", _ketika_berjalan)
		navigasi.connect("navigation_finished", _ketika_navigasi_selesai)
		mulai()

# fungsi untuk mengatur node ketika spawn
func mulai() -> void:
	pass

# fungsi yang akan dipanggil ketika id_proses diubah
func atur_pemroses(_id_pemroses : int) -> void:
	pass

## core ##
# arahkan untuk pergi ke posisi tertentu
func navigasi_ke(posisi : Vector3, _berlari : bool = false) -> void:
	navigasi.set_target_position(posisi)
	_proses_navigasi = true

# ketika diserang dengan nilai serangan tertentu
func _diserang(_penyerang : Node3D, _damage_serangan : int) -> void:
	pass

# hapus / hilangkan
func hapus() -> void:
	queue_free()

## event ##
# proses navigasi
func _physics_process(delta : float) -> void:
	if _proses_navigasi:
		var posisi_selanjutnya : Vector3 = navigasi.get_next_path_position()
		var posisi_saat_ini : Vector3 = global_position
		var arah : Vector3 = (posisi_selanjutnya - posisi_saat_ini).normalized() * kecepatan_gerak
		if navigasi.avoidance_enabled:
			navigasi.set_velocity(arah)
		else:
			_ketika_berjalan(arah)
	elif velocity != Vector3.ZERO:
		velocity.x = lerpf(velocity.x, 0, kecepatan_gerak * delta)
		velocity.y = 0
		velocity.z = lerpf(velocity.z, 0, kecepatan_gerak * delta)
	move_and_slide()

# arah ketika berjalan
func _ketika_berjalan(arah : Vector3) -> void:
	velocity = arah
	move_and_slide()
	
	# sinkronkan perubahan kondisi
	if id_proses == client.id_koneksi:
		if id_pengubah == 1:
			server._sesuaikan_properti_objek(1, name, [["global_transform:origin", global_transform.origin]])
		else:
			server.rpc_id(1, "_sesuaikan_properti_objek", id_pengubah, name, [["global_transform:origin", global_transform.origin]])
 
# ketika sampai di posisi tujuan
func _ketika_navigasi_selesai() -> void:
	if _proses_navigasi:
		_proses_navigasi = false

# ketika mati
func mati() -> void:
	Panku.notify(name+" mati >~<")

## debug ##
func _input(_event : InputEvent) -> void:
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if Input.is_action_just_pressed("daftar_pemain"): navigasi_ke(server.permainan.karakter.global_position)
