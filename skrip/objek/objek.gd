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
@export var kode : String :					# jika menggunakan kode ubahan
	set(kode_baru):
		if get_node_or_null("kode_ubahan") != null:
			if $kode_ubahan.block_script.generated_script != kode_baru:
				$kode_ubahan.block_script.generated_script = kode_baru
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
