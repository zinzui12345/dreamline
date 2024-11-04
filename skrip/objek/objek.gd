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
#const properti = []						# array berisi properti kustom yang akan di-sinkronkan ke server | format sama dengan kondisi pada server (Array[ Array[nama_properti, nilai] ]) | properti harus di @export!
#const jalur_instance = ""					# jalur aset skena node objek ini misalnya: "res://skena/objek/tembok.scn"
#const abaikan_transformasi = true			# hanya tambahkan jika objek tidak ingin diubah transformasinya dengan mode edit
#const abaikan_occlusion_culling = true		# hanya tambahkan jika objek tidak ingin dikalkulasi pada occlusion culling

@export var wilayah_render : AABB :
	set(aabb):
		if is_inside_tree():
			var tmp_aabb : Array = []
			for titik in 8:
				# terapkan posisi titik AABB ke array
				tmp_aabb.append(aabb.get_endpoint(titik))
			titik_sudut = tmp_aabb
		wilayah_render = aabb
@export var jarak_render : int = 10			# jarak maks render
@export var radius_keterlihatan : int = 50	# area batas frustum culling
@export var titik_sudut : Array = []		# titik tiap sudut AABB untuk occlusion culling
@export var cek_titik : int = 0				# simpan titik terakhir occlusion culling
@export var tak_terlihat : bool = false		# simpan kondisi frustum culling
@export var terhalang : bool = false		# simpan kondisi occlusion culling
@export var kode : BlockScriptSerialization :# jika menggunakan kode ubahan
	set(kode_baru):
		if get_node_or_null("kode_ubahan") != null and get_node("kode_ubahan") is BlockCode:
			if $kode_ubahan.block_script != kode_baru:
				$kode_ubahan.block_script = kode_baru
				$kode_ubahan._update_parent_script()
			kode = kode_baru

func _ready() -> void: call_deferred("_setup")
func _setup() -> void:
	if !is_instance_valid(server.permainan) or !is_instance_valid(server.permainan.dunia): return
	if get_parent().get_path() != server.permainan.dunia.get_node("objek").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and (not server.mode_replay or server.mode_uji_performa):
			var _sp_properti : Array	# array berisi properti kustom dengan nilai yang telah diubah pada objek | ini digunakan untuk menambahkan objek ke server
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
			else:
				print("[Galat] objek %s tidak memiliki properti!" % name)
			var _jalur_instance : String
			if get("jalur_instance") != null:
				_jalur_instance = get("jalur_instance")
			else:
				print("[Galat] objek %s tidak memiliki jalur skena!" % name)
			
			server._tambahkan_objek(
				_jalur_instance,
				global_transform.origin,
				rotation,
				jarak_render,
				_sp_properti
			)
		queue_free()
	else:
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
		var sinkron_kondisi : Array = get("properti")
		
		# cek apakah kondisi sebelumnya telah tersimpan
		if cek_properti.get("posisi") == null:	cek_properti["posisi"] = Vector3.ZERO
		if cek_properti.get("rotasi") == null:	cek_properti["rotasi"] = rotation
		if cek_properti.get("jarak_render") == null:	cek_properti["jarak_render"] = jarak_render
		
		# cek apakah kondisi berubah
		if cek_properti["posisi"] != position:	perubahan_kondisi.append(["position", position])
		if cek_properti["rotasi"] != rotation:	perubahan_kondisi.append(["rotation", rotation])
		if cek_properti["jarak_render"] != jarak_render:	perubahan_kondisi.append(["jarak_render", jarak_render])
		
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
						"path_child_pairs"				: _parse_sub_blok_kode($kode_ubahan.block_script.block_trees[cabang_blok].path_child_pairs),
						"block_serialized_properties"	: _parse_sub_properti_blok_kode($kode_ubahan.block_script.block_trees[cabang_blok].block_serialized_properties)
					}
				Panku.notify("jumlah blok kode diproses : "+str($kode_ubahan.block_script.block_trees.size()))
				Panku.notify("jumlah blok kode dikirim : "+str(parse_cabang_blok.size()))
				for indeks_data_variabel in $kode_ubahan.block_script.variables.size():
					parse_variabel_blok[str(indeks_data_variabel)+"|VariableResource"] = {
						"var_name":		$kode_ubahan.block_script.variables[indeks_data_variabel].var_name,
						"var_type":		$kode_ubahan.block_script.variables[indeks_data_variabel].var_type
					}
				var kirim_resource : Dictionary = {
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
		
		# simpan perubahan kode untuk di-cek lagi
		if get_node_or_null("kode_ubahan") != null and get_node("kode_ubahan") is BlockCode:
			cek_properti["kode"] = $kode_ubahan.block_script.generated_script
		
		# simpan perubahan kondisi properti kustom untuk di-cek lagi
		for p in sinkron_kondisi.size():
			cek_properti[sinkron_kondisi[p][0]] = get(sinkron_kondisi[p][0])

# 26/10/24 :: Fungsi sintaks blok kode
const BlockCategory = preload("res://skrip/editor kode/picker/categories/block_category.gd")
const BlocksCatalog = preload("res://skrip/editor kode/code_generation/blocks_catalog.gd")
const BlockDefinition = preload("res://skrip/editor kode/code_generation/block_definition.gd")
const Types = preload("res://skrip/editor kode/types/types.gd")

func get_custom_class() -> String:
	return "objek"
static func get_custom_categories() -> Array[BlockCategory]:
	return [BlockCategory.new("Objek")]
static func setup_custom_blocks():
	var _class_name = "objek"
	var block_list: Array[BlockDefinition] = []

	#var block_definition: BlockDefinition = BlockDefinition.new()
	#block_definition.name = &"fungsi_mulai"
	#block_definition.target_node_class = _class_name
	#block_definition.category = "%siklus%"
	#block_definition.type = Types.BlockType.ENTRY
	#block_definition.display_template = "mulai"
	#block_definition.description = "Fungsi yang dipanggil pada saat objek ditambahkan ke dunia."
	#block_definition.code_template = "func mulai():"
	#block_list.append(block_definition)

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
func _parse_sub_blok_kode(data : Array) -> Dictionary:
	var hasil_data : Dictionary = {}
	for sub_data in data.size():
		if data[sub_data] is Array and data[sub_data].size() == 2:
			hasil_data[str(sub_data)+"|Array"] = {
				"NodePath"				: data[sub_data][0],
				"BlockSerialization"	: {
					"name"							: data[sub_data][1].name,
					"position"						: data[sub_data][1].position,
					"path_child_pairs"				: _parse_sub_blok_kode(data[sub_data][1].path_child_pairs),
					"block_serialized_properties"	: _parse_sub_properti_blok_kode(data[sub_data][1].block_serialized_properties)
				}
			}
	return hasil_data
func _compile_sub_blok_kode(data : Dictionary) -> Array:
	var hasil_data : Array
	for sub_data in data:
		if data[sub_data] is Dictionary:
			var nama_blok : StringName = &"" + data[sub_data]["BlockSerialization"].name
			var tmp_pos_blok = data[sub_data]["BlockSerialization"].position
			var p_tmp_pos_blok = tmp_pos_blok.substr(1, tmp_pos_blok.length()-2)
			var c_tmp_pos_blok = p_tmp_pos_blok.split(", ", false)
			var posisi_blok : Vector2 = Vector2(c_tmp_pos_blok[0].to_float(), c_tmp_pos_blok[1].to_float())
			var sub_blok : Array = _compile_sub_blok_kode(data[sub_data]["BlockSerialization"].path_child_pairs)
			var properti : BlockSerializedProperties = _compile_sub_properti_blok_kode(data[sub_data]["BlockSerialization"].block_serialized_properties)
			hasil_data.append([
				NodePath(data[sub_data]["NodePath"]),
				BlockSerialization.new(
					nama_blok,
					posisi_blok,
					properti,
					sub_blok
				)
			])
	return hasil_data
func _parse_sub_properti_blok_kode(data : BlockSerializedProperties) -> Dictionary:
	var hasil_data : Dictionary = {}
	if data != null:
		hasil_data["block_class"] = data["block_class"]
		hasil_data["serialized_props"] = {}
		for sub_sub_properti in data["serialized_props"].size():
			var hasil_sub_data : Array
			if data["serialized_props"][sub_sub_properti] is Array:
				hasil_data["serialized_props"][str(sub_sub_properti) + "|" + type_string(typeof(data["serialized_props"][sub_sub_properti]))] = _parse_sub_sub_properti_blok_kode(data["serialized_props"][sub_sub_properti])
			elif data["serialized_props"][sub_sub_properti] is Dictionary:
				hasil_data["serialized_props"][data["serialized_props"].keys()[sub_sub_properti] + "|" + type_string(typeof(data["serialized_props"][sub_sub_properti]))] = _parse_sub_sub_properti_blok_kode(data["serialized_props"][sub_sub_properti])
	return hasil_data
func _parse_sub_sub_properti_blok_kode(data) -> Dictionary:
	var hasil_data : Dictionary
	if data is Dictionary:
		for indeks_sub_sub_properti in data:
			var tipe_data = type_string(typeof(data[indeks_sub_sub_properti]))
			if tipe_data == "Dictionary":
				hasil_data[str(indeks_sub_sub_properti) + "|" + tipe_data] = _parse_sub_sub_properti_blok_kode(data[indeks_sub_sub_properti])
			else:
				hasil_data[str(indeks_sub_sub_properti) + "|" + tipe_data] = data[indeks_sub_sub_properti]
	elif data is Array:
		for indeks_sub_sub_properti in data.size():
			var tipe_data = type_string(typeof(data[indeks_sub_sub_properti]))
			if tipe_data == "Dictionary":
				hasil_data[str(indeks_sub_sub_properti) + "|" + tipe_data] = _parse_sub_sub_properti_blok_kode(data[indeks_sub_sub_properti])
			else:
				hasil_data[str(indeks_sub_sub_properti) + "|" + tipe_data] = data[indeks_sub_sub_properti]
	return hasil_data
func _konversi_sub_properti_blok_kode(data, tipe_target : String):
	var hasil_data
	var pecah_data : PackedStringArray
	if data is String:
		pecah_data = data.split(", ")
	if tipe_target == "Color":
		hasil_data = Color(
			pecah_data[0].to_float(),
			pecah_data[1].to_float(),
			pecah_data[2].to_float(),
			pecah_data[3].to_float()
		)
	elif tipe_target == "Vector2":
		hasil_data = Vector2(
			pecah_data[0].to_float(),
			pecah_data[1].to_float()
		)
	elif tipe_target == "Vector3":
		hasil_data = Vector3(
			pecah_data[0].to_float(),
			pecah_data[1].to_float(),
			pecah_data[2].to_float()
		)
	elif tipe_target == "StringName":
		hasil_data = &"" + data
	elif tipe_target == "Array" or tipe_target == "Dictionary":
		hasil_data = _konversi_sub_sub_properti_blok_kode(data, tipe_target)
	else :
		hasil_data = data
	return hasil_data
func _konversi_sub_sub_properti_blok_kode(data : Dictionary, tipe_target : String):
	if tipe_target == "Array":
		var hasil_data : Array = []
		for indeks_sub_sub_properti in data:
			var p_tipe_properti : PackedStringArray = indeks_sub_sub_properti.split('|')
			hasil_data.append(
				_konversi_sub_properti_blok_kode(
					data[indeks_sub_sub_properti],
					p_tipe_properti[1]
				)
			)
		return hasil_data
	else:
		var hasil_data : Dictionary = {}
		for indeks_sub_sub_properti in data:
			var p_tipe_properti : PackedStringArray = indeks_sub_sub_properti.split('|')
			var src = data[indeks_sub_sub_properti]
			hasil_data[p_tipe_properti[0]] = _konversi_sub_properti_blok_kode(
				data[indeks_sub_sub_properti],
				p_tipe_properti[1]
			)
		return hasil_data
func _compile_sub_properti_blok_kode(data : Dictionary) -> BlockSerializedProperties:
	var hasil_data : BlockSerializedProperties
	var kelas_blok : StringName = &""+data["block_class"]
	var daftar_properti : Array = []
	for indeks_sub_properti in data["serialized_props"]:
		var hasil_sub_data : Array = []
		if data["serialized_props"][indeks_sub_properti] is Dictionary and data["serialized_props"][indeks_sub_properti].size() == 2:
			for indeks_sub_sub_properti in data["serialized_props"][indeks_sub_properti]:
				var p_tipe_properti : PackedStringArray = indeks_sub_sub_properti.split('|')
				hasil_sub_data.append(
					_konversi_sub_properti_blok_kode(
						data["serialized_props"][indeks_sub_properti][indeks_sub_sub_properti],
						p_tipe_properti[1]
					)
				)
		if hasil_sub_data.size() > 0:
			daftar_properti.append(hasil_sub_data)
	hasil_data = BlockSerializedProperties.new(
		kelas_blok,
		daftar_properti
	)
	return hasil_data
