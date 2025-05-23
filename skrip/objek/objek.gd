# 28/04/24
extends Node3D
class_name objek

var id_pengubah : int = -1:					# id peer/pemain yang mengubah objek ini
	set(id):
		if id == client.id_koneksi:
			set_process(true)
		else:
			set_process(false)
		id_pengubah = id
var cek_properti : Dictionary = {}			# simpan beberapa properti di tiap frame untuk membandingkan perubahan
var cek_koneksi : Array[String]				# simpan nama objek yang terkoneksi secara sementara sebelum setup() objek
var sinkron_kondisi : Array = []			# daftar properti yang disinkronkan ke server
#const properti = []						# array berisi properti kustom yang akan di-sinkronkan ke server | format sama dengan kondisi pada server (Array[ Array[nama_properti, nilai] ]) | properti harus di @export!
#const jalur_instance = ""					# jalur aset skena node objek ini misalnya: "res://skena/objek/tembok.scn"
#const abaikan_transformasi = true			# hanya tambahkan jika objek tidak ingin diubah transformasinya dengan mode edit
#const abaikan_occlusion_culling = true		# hanya tambahkan jika objek tidak ingin dikalkulasi pada occlusion culling

@export var audio : String :						# jika terdapat node audio
	set(data):
		var array_audio = JSON.parse_string(data) if data != "" else null
		if array_audio != null and array_audio is Dictionary:
			for _node_audio_ in array_audio:
				if get_node_or_null(_node_audio_) != null and get_node(_node_audio_) is AudioStreamPlayer3D:
					if array_audio[_node_audio_]["berbunyi"]:
						if ResourceLoader.exists(array_audio[_node_audio_]["jalur_audio"]):
							get_node(_node_audio_).stream = load(array_audio[_node_audio_]["jalur_audio"])
							get_node(_node_audio_).play(array_audio[_node_audio_]["posisi_durasi"])
						else:
							Panku.notify("404 : Audio tak ditemukan [%s]" % [array_audio[_node_audio_]["jalur_audio"]])
					else:
						get_node(_node_audio_).stop()
				else:
					Panku.notify("404 : Node tak ditemukan [%s]" % [_node_audio_])
		audio = data
@export var node_audio : Array[String]				# daftar node audio yang tersedia
@export var efek_cahaya : GlowBorderEffectObject	# node efek garis cahaya ketika entitas di-fokus / highlight
@export var wilayah_render : AABB :					# area batas culling
	set(aabb):
		if is_inside_tree():
			var tmp_aabb : Array = []
			for titik in 8:
				# terapkan posisi titik AABB ke array
				tmp_aabb.append(aabb.get_endpoint(titik))
			titik_sudut = tmp_aabb
		wilayah_render = aabb
@export var jarak_render : int = 10					# jarak maks render
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

func _ready() -> void:
	if process_mode == PROCESS_MODE_DISABLED and get_parent().process_mode == PROCESS_MODE_DISABLED: return
	else: call_deferred("_setup")
func _setup() -> void:
	if get_parent().get_path() != dunia.get_node("objek").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and (not server.mode_replay or server.mode_uji_performa):
			var _sp_properti : Array	# array berisi properti kustom dengan nilai yang telah diubah pada objek | ini digunakan untuk menambahkan objek ke server
			if has_meta("id_objek"):
				_sp_properti.append([
					"id_objek",
					get_meta("id_objek")
				])
			else:
				_sp_properti.append([
					"id_objek",
					name
				])
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
				push_error("[Galat] objek %s tidak memiliki properti!" % name)
			var _jalur_instance : String
			if get("jalur_instance") != null:
				_jalur_instance = get("jalur_instance")
			else:
				push_error("[Galat] objek %s tidak memiliki jalur skena!" % name)
			
			server._tambahkan_objek(
				_jalur_instance,
				global_transform.origin,
				rotation,
				jarak_render,
				_sp_properti
			)
		queue_free()
	else:
		# 03/03/25 :: buat daftar node suara/bunyi
		for node in get_children():
			if node is AudioStreamPlayer3D:
				node_audio.append(node.name)
		
		# panggil fungsi mulai
		mulai()

# fungsi yang akan dipanggil pada saat node memasuki SceneTree menggantikan _ready()
func mulai() -> void:
	pass
# fungsi untuk memindahkan posisi lokal objek berdasarkan jarak
func pindahkan(arah : Vector3) -> void:
	var posisi_perpindahan : Vector3 = global_transform.origin + arah
	server.fungsikan_objek(
		name,
		"pindahkan",
		[ arah ]
	)
	set_indexed("global_transform:origin", posisi_perpindahan)
# fungsi untuk memutar audio pada node audio yang terdapat pada objek
func putar_audio(nama_node_audio : String, jalur_file_audio : String, putar : bool, posisi_durasi : float = 0.0) -> void:
	var _data_audio_ = JSON.parse_string(dapatkan_data_audio())
	if _data_audio_ != null and _data_audio_ is Dictionary:
		if _data_audio_.get(nama_node_audio) != null:
			_data_audio_[nama_node_audio]["berbunyi"] = putar
			_data_audio_[nama_node_audio]["jalur_audio"] = jalur_file_audio
			_data_audio_[nama_node_audio]["posisi_durasi"] = posisi_durasi
	
	server.fungsikan_objek(
		name,
		"berbunyi",
		[ JSON.stringify(_data_audio_) ]
	)
# fungsi untuk menghapus objek, menghilangkan dari dunia dan server
func hilangkan() -> void:
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		# hapus dari dictionary pool_objek pada server
		server.pool_objek.erase(name)
		# Timeline : hapus objek
		var frame_sekarang : int = server.timeline["data"]["frame"]
		if not server.timeline.has(frame_sekarang): server.timeline[frame_sekarang] = {}
		server.timeline[frame_sekarang][name] = {
			"tipe": "hapus"
		}
	# hapus instance
	queue_free()

func _process(_delta : float) -> void:
	# hentikan proses jika node tidak berada dalam permainan
	if !is_instance_valid(server.permainan): set_process(false); return
	
	# sinkronkan perubahan kondisi
	if id_pengubah == client.id_koneksi:
		# buat variabel pembanding
		var perubahan_kondisi : Array = []
		
		if sinkron_kondisi.size() < 1:
			if (get("properti") != null): sinkron_kondisi = get("properti")
			elif has_meta("setelan"):
				var dictionary_setelan : Dictionary = get_meta("setelan")
				for setelan in dictionary_setelan:
					if setelan == "ikon": continue
					elif setelan == "kode": continue
					else:
						sinkron_kondisi.append([
							setelan,
							dictionary_setelan[setelan]
						])
		
		# cek apakah kondisi sebelumnya telah tersimpan
		if cek_properti.get("posisi") == null:	cek_properti["posisi"] = Vector3.ZERO
		if cek_properti.get("rotasi") == null:	cek_properti["rotasi"] = rotation
		if cek_properti.get("jarak_render") == null:	cek_properti["jarak_render"] = jarak_render
		
		# cek apakah kondisi berubah
		if cek_properti["posisi"] != position:	perubahan_kondisi.append(["position", position])
		if cek_properti["rotasi"] != rotation:	perubahan_kondisi.append(["rotation", rotation])
		if cek_properti["jarak_render"] != jarak_render:	perubahan_kondisi.append(["jarak_render", jarak_render])
		
		# cek pemutaran audio
		if !node_audio.is_empty():
			if cek_properti.get("audio") == null:	cek_properti["audio"] = dapatkan_data_audio()
			
			if cek_properti["audio"] != dapatkan_data_audio():
				perubahan_kondisi.append(["audio", dapatkan_data_audio()])
		
		# cek apakah kode berubah (jika ada)
		if get_node_or_null("kode_ubahan") != null and get_node("kode_ubahan") is BlockCode:
			# cek apakah kode sebelumnya telah tersimpan
			if cek_properti.get("kode") == null: cek_properti["kode"] = $kode_ubahan.block_script.generated_script
			
			# cek apakah kode berubah
			if cek_properti["kode"] != $kode_ubahan.block_script.generated_script:
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
		
		# cek kondisi properti kustom
		for p in sinkron_kondisi.size():
			# cek apakah kondisi sebelumnya telah tersimpan
			if cek_properti.get(sinkron_kondisi[p][0]) == null:	cek_properti[sinkron_kondisi[p][0]] = sinkron_kondisi[p][1]
			
			# cek apakah kondisi berubah
			if cek_properti[sinkron_kondisi[p][0]] != get(sinkron_kondisi[p][0]):	perubahan_kondisi.append([sinkron_kondisi[p][0], get(sinkron_kondisi[p][0])])
		
		# jika kondisi berubah, maka sinkronkan perubahan ke server
		if perubahan_kondisi.size() > 0:
			if id_pengubah == 1:
				server._sesuaikan_properti_objek(1, name, perubahan_kondisi)
			else:
				server.rpc_id(1, "_sesuaikan_properti_objek", id_pengubah, name, perubahan_kondisi)
		
		# simpan perubahan kondisi untuk di-cek lagi
		cek_properti["posisi"] = position
		cek_properti["rotasi"] = rotation
		cek_properti["jarak_render"] = jarak_render
		
		# simpan pemutaran audio untuk di-cek lagi
		if !node_audio.is_empty():
			cek_properti["audio"] = dapatkan_data_audio()
		
		# simpan perubahan kode untuk di-cek lagi
		if get_node_or_null("kode_ubahan") != null and get_node("kode_ubahan") is BlockCode:
			cek_properti["kode"] = $kode_ubahan.block_script.generated_script
		
		# simpan perubahan kondisi properti kustom untuk di-cek lagi
		for p in sinkron_kondisi.size():
			cek_properti[sinkron_kondisi[p][0]] = get(sinkron_kondisi[p][0])

# 03/03/25 :: fungsi untuk mendapatkan data audio dari node audio
func dapatkan_data_audio() -> String:
	var gabung_data : Dictionary
	for node_ in node_audio:
		var node_audio_ : AudioStreamPlayer3D = get_node(node_)
		gabung_data[node_] = {
			"berbunyi":			node_audio_.playing,
			"jalur_audio":		node_audio_.stream.resource_path if node_audio_.stream != null else "",
			"posisi_durasi":	node_audio_.get_playback_position()
		}
	return JSON.stringify(gabung_data)

# 26/10/24 :: Fungsi sintaks blok kode
const BlockCategory = preload("res://skrip/editor kode/picker/categories/block_category.gd")
const BlocksCatalog = preload("res://skrip/editor kode/code_generation/blocks_catalog.gd")
const BlockDefinition = preload("res://skrip/editor kode/code_generation/block_definition.gd")
const Types = preload("res://skrip/editor kode/types/types.gd")

static func get_custom_class() -> String:	return "objek"
static func get_custom_categories() -> Array[BlockCategory]:
	return [BlockCategory.new("Objek")]
func setup_custom_blocks() -> void:
	var _class_name = "objek"
	var block_list: Array[BlockDefinition] = []
	
	# 28/02/25 :: buat blok kode node suara/bunyi
	for node in node_audio:
		var block_definition: BlockDefinition = BlockDefinition.new()
		block_definition.name = &"play_sound_" + node
		block_definition.description = "%deskripsi_putar_suara%"
		block_definition.target_node_class = _class_name
		block_definition.category = "%suara%"
		block_definition.type = Types.BlockType.STATEMENT
		#block_definition.variant_type = TYPE_STRING
		block_definition.display_template = "%putar_suara {nilai: AUDIO} " + TranslationServer.translate("%putar_suara_x_pada_node%") + " $" + node
		block_definition.code_template = "putar_audio(\""+node+"\", \"{nilai}\", true)"
		block_list.append(block_definition)
	
	#BlocksCatalog.add_custom_blocks(_class_name, block_list)
	
	var property_list: Array[Dictionary] = [
		{
			"name": "radius_keterlihatan",
			"type": TYPE_INT,
		},
		{
			"name": "jarak_render",
			"type": TYPE_INT,
		}
	]
	
	var property_settings = {
		"radius_keterlihatan":
		{
			"category": "%variabel%",
			"default_set": 50,
		},
		"jarak_render":
		{
			"category": "%variabel%",
			"default_set": 10,
		}
	}

	BlocksCatalog.add_custom_blocks(_class_name, block_list, property_list, property_settings)
