# 03/11/23
extends CharacterBody3D
class_name npc_ai

const sinkron_kondisi : Array = [["arah_pandangan", 0.0], ["animasi", "{}"]]

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

@export var animasi : String :						# jika terdapat node animasi
	set(data):
		var array_animasi = JSON.parse_string(data)
		if array_animasi != null and array_animasi is Dictionary:
			for _node_animasi_ in array_animasi:
				if get_node_or_null(_node_animasi_) != null and get_node(_node_animasi_) is AnimationPlayer:
					var pemutar_animasi : AnimationPlayer = get_node(_node_animasi_)
					if array_animasi[_node_animasi_]["memutar"]:
						if pemutar_animasi.has_animation(array_animasi[_node_animasi_]["nama_animasi"]):
							if !pemutar_animasi.is_playing() or pemutar_animasi.current_animation != array_animasi[_node_animasi_]["nama_animasi"]:
								if array_animasi[_node_animasi_]["posisi_durasi"] == 0.0:
									pemutar_animasi.play(array_animasi[_node_animasi_]["nama_animasi"])
								elif array_animasi[_node_animasi_]["posisi_durasi"] > 0.0:
									pemutar_animasi.play(array_animasi[_node_animasi_]["nama_animasi"])
									pemutar_animasi.seek(array_animasi[_node_animasi_]["posisi_durasi"])
						else:
							Panku.notify("404 : Animasi tak ditemukan [%s]" % [array_animasi[_node_animasi_]["nama_animasi"]])
					else:
						pemutar_animasi.stop()
				else:
					Panku.notify("404 : Node tak ditemukan [%s]" % [_node_animasi_])
		animasi = data
@export var node_animasi : Array					# daftar node animasi yang tersedia
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
func _ready() -> void:
	if process_mode == PROCESS_MODE_DISABLED and get_parent().process_mode == PROCESS_MODE_DISABLED: return
	else: call_deferred("_setup")
func _setup() -> void:
	if get_parent().get_path() != dunia.get_node("karakter").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and (not server.mode_replay or server.mode_uji_performa):
			var _sp_properti : Array	# array berisi properti kustom dengan nilai yang telah diubah pada karakter | ini digunakan untuk menambahkan karakter ke server
			if get("sinkron_kondisi") != null:
				for properti_kustom : Array in get("sinkron_kondisi"):
					_sp_properti.append([
						properti_kustom[0],
						get(properti_kustom[0])
					])
				if get_node_or_null("kode_ubahan") != null and get_node("kode_ubahan") is BlockCode:
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
					_sp_properti.append([
						"kode",
						JSON.stringify(kirim_resource)
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
		if model != null:
			for node in model.get_children():
				if node is AnimationPlayer:
					node_animasi.append(["model/" + node.name, "AnimationPlayer"])
				elif node is AnimationTree:
					node_animasi.append(["model/" + node.name, "AnimationTree"])
		set("arah_pandangan", arah_pandangan)
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

# putar animasi tertentu
func putar_animasi(jalur_node_animasi : String, nama_animasi : String, putar : bool) -> void:
	var pemutar_animasi = get_node_or_null(jalur_node_animasi)
	if pemutar_animasi != null:
		var _data_animasi_ = JSON.parse_string(dapatkan_data_animasi())
		if _data_animasi_ != null and _data_animasi_ is Dictionary:
			if _data_animasi_.get(jalur_node_animasi) != null:
				_data_animasi_[jalur_node_animasi]["memutar"] = putar
				_data_animasi_[jalur_node_animasi]["nama_animasi"] = nama_animasi
				_data_animasi_[jalur_node_animasi]["posisi_durasi"] = 0.0
		set("animasi", JSON.stringify(_data_animasi_))

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
		
		# cek pemutaran animasi
		if !node_animasi.is_empty():
			if cek_kondisi.get("animasi") == null:	cek_kondisi["animasi"] = dapatkan_data_animasi()
			
			if cek_kondisi["animasi"] != dapatkan_data_animasi():
				perubahan_kondisi.append(["animasi", dapatkan_data_animasi()])
		
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
		
		# simpan pemutaran animasi untuk di-cek lagi
		if !node_animasi.is_empty():
			cek_kondisi["animasi"] = dapatkan_data_animasi()
		
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

# 07/03/25 :: fungsi untuk mendapatkan data animasi dari node animasi
func dapatkan_data_animasi() -> String:
	var gabung_data : Dictionary
	for node_ in node_animasi:
		var node_animasi_ = get_node(node_[0])
		if node_animasi_ is AnimationPlayer and node_[1] == "AnimationPlayer":
			gabung_data[node_[0]] = {
				"memutar":			node_animasi_.is_playing(),
				"nama_animasi":		node_animasi_.current_animation if node_animasi_.is_playing() else "",
				"posisi_durasi":	node_animasi_.current_animation_position if node_animasi_.is_playing() else 0.0
			}
	return JSON.stringify(gabung_data)

## debug ##
func _input(_event : InputEvent) -> void:
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if Input.is_action_just_pressed("daftar_pemain"): _diserang(server.permainan.get_node("../dunia/pemain/"+str(client.id_koneksi)), 7)

# 26/10/24 :: Fungsi sintaks blok kode
const BlockCategory = preload("res://skrip/editor kode/picker/categories/block_category.gd")
const BlocksCatalog = preload("res://skrip/editor kode/code_generation/blocks_catalog.gd")
const BlockDefinition = preload("res://skrip/editor kode/code_generation/block_definition.gd")
const Types = preload("res://skrip/editor kode/types/types.gd")

static func get_custom_class() -> String:	return "npc_ai"
static func get_custom_categories() -> Array[BlockCategory]:
	return [BlockCategory.new("%karakter%")]
func setup_custom_blocks():
	var _class_name = "npc_ai"
	var block_list: Array[BlockDefinition] = []
	
	# 06/03/25 :: buat blok kode node animasi
	# TODO : blok kode node AnimationTree
	# loop data_node lagi untuk mencari node AnimationTree
	# kalau properti active di AnimationTree true, cek node AnimationPlayer di properti anim_player
	# terus hapus blok kode AnimationPlayer itu
	# selain itu gak usah lakuin apa-apa
	for data_node in node_animasi:
		if data_node[1] == "AnimationPlayer":
			var block_definition: BlockDefinition = BlockDefinition.new()
			var _node_animasi_ = get_node(data_node[0])
			
			block_definition.name = &"play_animation_" + _node_animasi_.name
			block_definition.description = "%deskripsi_putar_animasi%"
			block_definition.target_node_class = _class_name
			block_definition.category = "%animasi%"
			block_definition.type = Types.BlockType.STATEMENT
			block_definition.display_template = "%putar_animasi {animasi: OPTION} " + TranslationServer.translate("%putar_animasi_x_pada_node%") + " $" + data_node[0]
			block_definition.code_template = "putar_animasi(\""+data_node[0]+"\", \"{animasi}\", true)"
			block_definition.defaults = {
				"animasi": OptionData.new(_node_animasi_.get_animation_list())
			}
			
			block_list.append(block_definition)
	
	var property_list: Array[Dictionary] = [
		{
			"name": "nyawa",
			"type": TYPE_INT,
		}
	]
	var property_settings = {
		"nyawa":
		{
			"category": "%variabel%",
			"default_set": 100,
		}
	}
	BlocksCatalog.add_custom_blocks(_class_name, block_list, property_list, property_settings)
