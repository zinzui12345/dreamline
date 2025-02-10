# 03/11/23
extends CharacterBody3D
class_name npc_ai

# TODO : sinkronkan arah melihat

const sinkron_kondisi : Array = [["arah_pandangan", 0.0]]

var model : Node3D
var navigasi : NavigationAgent3D
var _proses_navigasi : bool = false
var timer_proses : float = 0.0
var arah_pandangan = 0.0 :
	set(nilai):
		if model != null:
			model.rotation.y = nilai
			$fisik.rotation.y = nilai
		arah_pandangan = nilai
var id_proses : int = -1:					# id peer/pemain yang memproses npc ini
	set(id):
		id_proses = id
		atur_pemroses(id)
		if id == client.id_koneksi:
			set_process(true)
			set_physics_process(true)
		#Panku.notify("ini kecetak?")
var id_pengubah : int = -1:					# id peer/pemain yang mengubah npc ini
	set(id):
		id_pengubah = id
		if id == client.id_koneksi:
			set_process(true)
			set_physics_process(true)
			#Panku.notify("disini yang penyinkron")
		elif client.id_koneksi == id_proses:
			if id == -1 or id == 0:
				set_process(true)
				set_physics_process(true)
				#Panku.notify("disini yang jadi penyinkron")
			else:
				set_process(false)
				set_physics_process(false)
				#Panku.notify("disini bukan penyinkron")
		#Panku.notify("ini kecetak? gak???")
var posisi_awal : Vector3					# simpan posisi awal npc
var rotasi_awal : Vector3					# simpan rotasi awal npc
var cek_kondisi : Dictionary = {}			# simpan beberapa properti di tiap frame untuk membandingkan perubahan

enum grup {
	pemain,		# + teman, mis: hewan 
	netral,		# = hewan liar
	musuh		# - monster
}
enum varian_kondisi {
	diam,		# berdiam di tempat
	keliling,	# navigasi ke posisi acak
	mengejar,	# menarget musuh
	menyerang,	# menyerang musuh
	menghindar,	# menjauh dari musuh
	mati		# gak usah ditanya lagi!
}

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
				cek_kondisi["kode"] = kode_baru.generated_script
				$kode_ubahan.block_script = kode_baru
				$kode_ubahan._update_parent_script()
			kode = kode_baru

## setup ##
func _ready() -> void: call_deferred("_setup")
func _setup() -> void:
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
			if get("jalur_instance") != null:
				_jalur_instance = get("jalur_instance")
			else:
				push_error("[Galat] npc %s tidak memiliki jalur skena!" % name)
			
			server._tambahkan_karakter(
				_jalur_instance,
				global_transform.origin,
				rotation,
				_sp_properti
			)
		queue_free()
	else:
		model = get_node_or_null("model")
		navigasi = $navigasi
		navigasi.avoidance_enabled = true
		navigasi.connect("velocity_computed", _ketika_berjalan)
		navigasi.connect("navigation_finished", _ketika_navigasi_selesai)
		mulai()

# fungsi untuk mengatur node ketika spawn
func mulai() -> void:
	pass

# fungsi yang akan dipanggil setiap saat menggantikan _process(delta)
func proses(_waktu_delta : float) -> void:
	pass

# fungsi yang akan dipanggil ketika id_proses diubah
func atur_pemroses(_id_pemroses : int) -> void:
	pass

## core ##
# arahkan untuk pergi ke posisi tertentu
func navigasi_ke(posisi : Vector3, _berlari : bool = false) -> void:
	if posisi == global_position: return
	if id_pengubah == client.id_koneksi or id_proses == client.id_koneksi:
		navigasi.set_target_position(posisi)
		_proses_navigasi = true

# arahkan model ke posisi tertentu
func lihat_ke(posisi : Vector3):
	if model != null:
		model.look_at(posisi, Vector3.UP, true)
		model.rotation.x = 0
		arah_pandangan = model.rotation.y

# ketika diserang dengan nilai serangan tertentu
func _diserang(_penyerang : Node3D, _damage_serangan : int) -> void:
	pass

# hapus / hilangkan
func hapus() -> void:
	queue_free()

## event ##
func _process(delta : float) -> void:
	# hentikan proses jika node tidak berada dalam permainan
	if !is_instance_valid(server.permainan): set_process(false); return
	
	# hentikan proses pada peer yang bukan pemroses atau pengubah
	if id_pengubah != client.id_koneksi and id_proses != client.id_koneksi:
		set_process(false)
		set_physics_process(false)
		#Panku.notify("disini bukan penyinkron, membatalkan sinkronisasi")
	
	else:
		# buat variabel pembanding
		var perubahan_kondisi = []
		var sinkron_kondisi : Array = get("sinkron_kondisi")
		
		# cek apakah kondisi sebelumnya telah tersimpan
		if cek_kondisi.get("posisi") == null:	cek_kondisi["posisi"] = Vector3.ZERO
		if cek_kondisi.get("rotasi") == null:	cek_kondisi["rotasi"] = rotation
		
		# cek apakah kode berubah (jika ada)
		if get_node_or_null("kode_ubahan") != null and get_node("kode_ubahan") is BlockCode:
			# cek apakah kode sebelumnya telah tersimpan
			if cek_kondisi.get("kode") == null: cek_kondisi["kode"] = $kode_ubahan.block_script.generated_script
			
			# cek apakah kode berubah
			if cek_kondisi["kode"] != $kode_ubahan.block_script.generated_script:
				var parse_cabang_blok : Dictionary
				var parse_variabel_blok : Dictionary
				for cabang_blok in $kode_ubahan.block_script.block_trees.size():
					parse_cabang_blok[str(cabang_blok)+"|BlockSerialization"] = {
						"name"							: $kode_ubahan.block_script.block_trees[cabang_blok].name,
						"position"						: $kode_ubahan.block_script.block_trees[cabang_blok].position,
						"path_child_pairs"				: server.permainan._parse_sub_blok_kode($kode_ubahan.block_script.block_trees[cabang_blok].path_child_pairs),
						"block_serialized_properties"	: server.permainan._parse_sub_properti_blok_kode($kode_ubahan.block_script.block_trees[cabang_blok].block_serialized_properties)
					}
				for indeks_data_variabel in $kode_ubahan.block_script.variables.size():
					parse_variabel_blok[str(indeks_data_variabel)+"|VariableResource"] = {
						"var_name":		$kode_ubahan.block_script.variables[indeks_data_variabel].var_name,
						"var_type":		$kode_ubahan.block_script.variables[indeks_data_variabel].var_type
					}
				var kirim_resource : Dictionary = {
					"script_inherits":	$kode_ubahan.block_script.script_inherits,
					"block_trees":		parse_cabang_blok,
					"variables":		parse_variabel_blok,
					"generated_script":	$kode_ubahan.block_script.generated_script
				}
				perubahan_kondisi.append(["kode", JSON.stringify(kirim_resource)])
		
		# reset kondisi jika npc jatuh ke void
		if global_position.y < server.permainan.batas_bawah:
			perubahan_kondisi.append(["position", posisi_awal])
			perubahan_kondisi.append(["rotation", rotasi_awal])
			global_transform.origin = posisi_awal
			rotation		 		= rotasi_awal
		
		# cek apakah kondisi berubah
		else:
			if cek_kondisi["posisi"] != position:	perubahan_kondisi.append(["position", position])
			if cek_kondisi["rotasi"] != rotation:	perubahan_kondisi.append(["rotation", rotation])
		
		# cek kondisi properti kustom
		for p in sinkron_kondisi.size():
			# cek apakah kondisi sebelumnya telah tersimpan
			if cek_kondisi.get(sinkron_kondisi[p][0]) == null:	cek_kondisi[sinkron_kondisi[p][0]] = sinkron_kondisi[p][1]
			
			# cek apakah kondisi berubah
			if cek_kondisi[sinkron_kondisi[p][0]] != get(sinkron_kondisi[p][0]):	perubahan_kondisi.append([sinkron_kondisi[p][0], get(sinkron_kondisi[p][0])])
		
		# jika kondisi berubah, maka sinkronkan perubahan ke server
		if perubahan_kondisi.size() > 0:
			if id_proses == 1:
				server._sesuaikan_kondisi_karakter(1, name, perubahan_kondisi)
			elif id_pengubah == client.id_koneksi:
				server.rpc_id(1, "_sesuaikan_kondisi_karakter", id_pengubah, name, perubahan_kondisi)
			else:
				server.rpc_id(1, "_sesuaikan_kondisi_karakter", id_proses, name, perubahan_kondisi)
		
		# simpan perubahan kondisi untuk di-cek lagi
		cek_kondisi["posisi"] = position
		cek_kondisi["rotasi"] = rotation
		
		# simpan perubahan kode untuk di-cek lagi
		if get_node_or_null("kode_ubahan") != null and get_node("kode_ubahan") is BlockCode:
			cek_kondisi["kode"] = $kode_ubahan.block_script.generated_script
		
		# simpan perubahan kondisi properti kustom untuk di-cek lagi
		for p in sinkron_kondisi.size():
			cek_kondisi[sinkron_kondisi[p][0]] = get(sinkron_kondisi[p][0])
		
		# panggil fungsi pemroses npc setiap 200 milidetik
		timer_proses += delta
		if timer_proses >= 0.2:
			proses(delta)
			timer_proses = 0.0

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

# 26/10/24 :: Fungsi sintaks blok kode
const BlockCategory = preload("res://skrip/editor kode/picker/categories/block_category.gd")
const BlocksCatalog = preload("res://skrip/editor kode/code_generation/blocks_catalog.gd")
const BlockDefinition = preload("res://skrip/editor kode/code_generation/block_definition.gd")
const Types = preload("res://skrip/editor kode/types/types.gd")

func get_custom_class() -> String:	return "npc_ai"
static func get_custom_categories() -> Array[BlockCategory]:
	return [BlockCategory.new("%karakter%")]
