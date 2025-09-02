extends Node

class_name Server

@onready var permainan = get_tree().get_root().get_node("Dreamline")

var interface = null
var peer : MultiplayerPeer
var broadcast : ServerAdvertiser
var upnp : UPNP
var headless : bool = false
var publik : bool = false
var ip_publik
var jumlah_pemain : int = 32
var pemain_terhubung : int = 0
var map : StringName = &"pulau"
var nama : StringName = &"bebas"
var pemain : Dictionary
var timeline : Dictionary = {}
var mode_replay : bool = false
var mode_uji_performa : bool = false
var jumlah_entitas : int = 0
var jumlah_objek : int = 0
var jumlah_karakter : int = 0
var pool_entitas : Dictionary = {}
var pool_objek : Dictionary = {}
var pool_karakter : Dictionary = {}
var cek_visibilitas_pemain : Dictionary = {} # [id_pemain][id_pemain_target] = "spawn" ? "hapus"
var cek_visibilitas_pool_entitas : Dictionary = {} # [id_pemain][nama_entitas] = "spawn" ? "hapus"
var cek_visibilitas_pool_objek : Dictionary = {} # [id_pemain][nama_objek] = "spawn" ? "hapus"
var cek_visibilitas_pool_karakter : Dictionary = {} # [id_pemain][nama_karakter] = "spawn" ? "hapus"
var b_cek_data_timeline : Dictionary
var b_indeks_timeline : Array
var b_nama_file_timeline : String
var b_file_timeline : FileAccess

const jarak_render_karakter = 60 # harus melebihi jarak render entitas supaya kendaraan berfungsi normal
const jarak_render_entitas = 50
const direktori_cache_replay = "user://timeline_part"
const file_replay = "user://rekaman.dreamline_replay"

# .: Timeline :.
# frame : Int
# timeline[frame] : Dictionary
# timeline[frame][id_entity] = { tipe: string, tipe_entitas: string, sumber: string, data: { posisi, rotasi, skala, kondisi } }
# frame adalah nilai Time.get_ticks_msec() dikurangi waktu pada saat dunia di spawn
# timeline["data"]["mulai"] adalah Time.get_ticks_msec() pada saat dunia di spawn
# timeline["data"]["frame"] adalah Time.get_ticks_msec() dikurangi timeline[0]["mulai"]
# timeline["data"]["id"] adalah karakter acak untuk identifikasi bagian timeline pada suatu sesi permainan
# timeline["data"]["urutan"] adalah posisi urutan bagian timeline pada suatu sesi permainan
# :: penggunaan ::
# timeline[12][1] = { "spawn", "pintu", "res://model/pintu/pintuffburik.scn", "data": { Vec3(12, 1, 10), Vec3(0, 122, 0), Vec3(1, 1, 1), { "arah_gerak": Vec3(0.33, 0, 1.5) } } }
# timeline[12][1] = { "sinkron", "posisi": Vec3(12, 1, 10), "rotasi": Vec3(0, 122, 0), "skala": Vec3(1, 1, 1), "kondisi": { "arah_gerak": Vec3(0.33, 0, 1.5) } }
# timeline[12][1] = { "hapus" }

# .: Entitas :.
# pool_entitas[nama_entitas]["id_pengubah"] = id_pengubah
# pool_entitas[nama_entitas][nama_properti] = nilai_properti
# pool_entitas{
# 	"entitas_1" : {
#		"id_proses": -1,
#		"id_pengubah": 0,
# 		"posisi" : Vector3i(988, 4, 75),
# 		"rotasi" : Vector3(25.7, 90, 6),
#		"kondisi": {}
# 	},
# 	"entitas_2" : {
#		"id_proses": -1,
#		"id_pengubah": 0,
# 		"posisi" : Vector3i(64, 443, 8),
# 		"rotasi" : Vector3(11.9, 88, 0),
#		"kondisi": {}
# 	}
# }
# kalau pool_entitas[nama_entitas]["id_pengubah"] == 0, ubah pool_entitas[nama_entitas]["id_pengubah"] menjadi id_pengubah
# kalau pool_entitas[nama_entitas]["id_pengubah"] == id_pengubah, maka pengubah mendapat akses untuk mengatur properti
# ketika pengubah berhenti mengedit pool_entitas, atur pool_entitas[nama_entitas]["id_pengubah"] menjadi 0
# terapkan nilai atur_properti() kalau pool_entitas[nama_entitas]["id_pengubah"] == id_pengubah

# .: Objek :.
# objek berbeda dengan entitas
# objek tidak memerlukan pemroses tetapi tetap memiliki id_pengubah
# pool_objek spawn hanya ketika berada di dekat pemain dan di didepan pemain (culling)
# pool_objek spawn dan de-spawn secara batch di client
# client dapat me-non-aktifkan culling pool_objek untuk tech demo
# tiap objek pool_objek memiliki jarak rendernya masing-masing
# objek dapat diabaikan dari occlusion culling
# occlusion culling diproses secara lokal di client
# pool_objek{
# 	"objek_1" : {
#		"jarak_render": 0,
#		"id_pengubah": 0,
# 		"posisi" : Vector3i(988, 4, 75),
# 		"rotasi" : Vector3(25.7, 90, 6),
#		"properti": {}
# 	},
# 	"objek_2" : {
#		"jarak_render": 0,
#		"id_pengubah": 0,
# 		"posisi" : Vector3i(64, 443, 8),
# 		"rotasi" : Vector3(11.9, 88, 0),
#		"properti": {}
# 	}
# }

# .: Karakter :.
# karakter adalah gabungan dari objek dan entitas
# karakter memerlukan pemroses dan memiliki id_pengubah
# pool_karakter spawn hanya ketika berada di dekat pemain dan di didepan pemain (culling)
# pool_karakter spawn dan de-spawn secara batch di client
# pool_karakter{
# 	"karakter_1" : {
#		"id_proses": -1,
#		"id_pengubah": 0,
# 		"posisi" : Vector3i(988, 4, 75),
# 		"rotasi" : Vector3(25.7, 90, 6),
#		"kondisi": {}
# 	}
# }

const POSISI_SPAWN_RANDOM := 5.0

func _process(_delta : float) -> void:
	if permainan != null and permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		# hanya dalam permainan
		if not mode_replay:
			# atur frame timeline
			if dunia.process_mode != PROCESS_MODE_DISABLED and timeline.has("data"):
				if timeline.size() > 400:
					b_cek_data_timeline = timeline["data"]
					# hasilkan nama_file
					b_nama_file_timeline = "timeline_%s-%s-%s_%s.timelinepart" % [map, nama, timeline["data"]["id"], timeline["data"]["urutan"]]
					# simpan data timeline ke nama_file
					# - hapus timeline["data"], sisakan data frame
					timeline.erase("data")
					# - kalau direktori bagian belum ada, buat
					if !DirAccess.dir_exists_absolute(direktori_cache_replay):
						DirAccess.make_dir_absolute(direktori_cache_replay)
					b_file_timeline = FileAccess.open(direktori_cache_replay+"/"+b_nama_file_timeline, FileAccess.WRITE)
					# - jangan langsung stor, hapus dulu frame yang kosong!
					b_indeks_timeline = timeline.keys()
					for frame : int in b_indeks_timeline.size(): 
						if timeline[b_indeks_timeline[frame]].size() < 1:
							timeline.erase(b_indeks_timeline[frame])
					b_file_timeline.store_var(timeline)
					# kosongkan data frame timeline
					timeline.clear()
					timeline["data"] = b_cek_data_timeline
					# tambah urutan
					timeline["data"]["urutan"] += 1
					# 15/07/24 :: unset variabel
					b_indeks_timeline.clear()
					b_file_timeline.close()
					b_nama_file_timeline = ""
				else:
					timeline["data"]["frame"] = Time.get_ticks_msec() - timeline["data"]["mulai"]
			
			# tentukan visibilitas tiap pemain berdasarkan pemain lain
			var indeks_pool_pemain : Array = pemain.keys()
			for i_pool_pemain in indeks_pool_pemain:
				var id_pemain : int = pemain[i_pool_pemain]["id_client"]
				
				# hanya proses pemain yang aktif
				if id_pemain != 0:
					# 30/06/24 :: loop pemain lain, kemudian cek visibilitasnya
					for pemain_target in indeks_pool_pemain:
						var id_pemain_target : int = pemain[pemain_target]["id_client"]
						var data_pemain_target : Dictionary = pemain[pemain_target]
						# hanya proses pemain selain pemain dan pemain yang aktif
						if id_pemain != id_pemain_target and id_pemain_target != 0:
							# cek jarak pemain dengan pemain target
							var jarak_pemain : float = pemain[i_pool_pemain]["posisi"].distance_to(pemain[pemain_target]["posisi"])
							# pastikan keadaan visibilitas pool
							if cek_visibilitas_pemain.get(id_pemain) == null:
								cek_visibilitas_pemain[id_pemain] = {}
							if cek_visibilitas_pemain[id_pemain].get(id_pemain_target) == null:
								cek_visibilitas_pemain[id_pemain][id_pemain_target] = "hapus"
							# jika jarak pemain target lebih dari jarak render karakter
							if jarak_pemain > jarak_render_karakter:
								# hanya hapus jika pool telah di-spawn
								if cek_visibilitas_pemain[id_pemain][id_pemain_target] == "spawn":
									# rpc hapus pool pemain
									hapus_pool_pemain(id_pemain, id_pemain_target)
									# ubah visibilitas pool agar jangan rpc lagi
									cek_visibilitas_pemain[id_pemain][id_pemain_target] = "hapus"
							# jika jarak pemain kurang dari jarak render karakter
							else:
								# hanya spawn jika pool belum di-spawn
								if cek_visibilitas_pemain[id_pemain][id_pemain_target] == "hapus":
									# rpc spawn pool pemain
									spawn_pool_pemain(id_pemain, id_pemain_target, data_pemain_target)
									# ubah visibilitas pool agar jangan rpc lagi
									cek_visibilitas_pemain[id_pemain][id_pemain_target] = "spawn"
		
		# tentukan visibilitas entitas dan objek pada tiap pemain
		if !pemain.is_empty():
			var indeks_pool_pemain = pemain.keys()
			for i_pool_pemain in indeks_pool_pemain:
				var id_pemain = pemain[i_pool_pemain]["id_client"]
				
				# hanya proses pemain yang aktif
				if id_pemain != 0:
					# loop array pool_entitas
					if !pool_entitas.is_empty():
						var indeks_pool_entitas = pool_entitas.keys()
						for i_pool_entitas in indeks_pool_entitas.size(): 
							var nama_entitas = indeks_pool_entitas[i_pool_entitas]
							# cek jarak pemain dengan entitas
							var jarak_pemain = pemain[i_pool_pemain]["posisi"].distance_to(pool_entitas[nama_entitas]["posisi"])
							# pastikan keadaan visibilitas pool
							if cek_visibilitas_pool_entitas.get(id_pemain) == null:
								cek_visibilitas_pool_entitas[id_pemain] = {}
							if cek_visibilitas_pool_entitas[id_pemain].get(nama_entitas) == null:
								cek_visibilitas_pool_entitas[id_pemain][nama_entitas] = "hapus"
							# jika jarak pemain lebih dari jarak render entitas
							if jarak_pemain > jarak_render_entitas:
								# pastikan pemain saat ini tidak mengubah entitas
								if pool_entitas[nama_entitas]["id_pengubah"] != id_pemain:
									# cek jika id_proses telah diatur dan pemain saat ini adalah pemroses
									if pool_entitas[nama_entitas]["id_proses"] != -1 and pool_entitas[nama_entitas]["id_proses"] == id_pemain:
										# rpc atur -1 sebagai pemroses entitas ke semua peer
										sinkronkan_kondisi_entitas(-1, nama_entitas, [["id_proses", -1]])
										# atur id_proses dengan -1
										pool_entitas[nama_entitas]["id_proses"] = -1
									# hanya hapus jika pool telah di-spawn
									if cek_visibilitas_pool_entitas[id_pemain][nama_entitas] == "spawn":
										# rpc hapus pool_entitas
										hapus_pool_entitas(id_pemain, nama_entitas)
										# ubah visibilitas pool agar jangan rpc lagi
										cek_visibilitas_pool_entitas[id_pemain][nama_entitas] = "hapus"
							# jika jarak pemain kurang dari jarak render entitas
							else:
								# hanya spawn jika pool belum di-spawn
								if cek_visibilitas_pool_entitas[id_pemain][nama_entitas] == "hapus":
									# rpc spawn pool entitas
									spawn_pool_entitas(id_pemain, nama_entitas, pool_entitas[nama_entitas]["jalur_instance"], pool_entitas[nama_entitas]["id_proses"], pool_entitas[nama_entitas]["posisi"], pool_entitas[nama_entitas]["rotasi"], pool_entitas[nama_entitas]["kondisi"])
									# ubah visibilitas pool agar jangan rpc lagi
									cek_visibilitas_pool_entitas[id_pemain][nama_entitas] = "spawn"
								# cek jika id_proses belum diatur
								if pool_entitas[nama_entitas]["id_proses"] == -1:
									# rpc atur pemain sebagai pemroses entitas ke semua peer
									sinkronkan_kondisi_entitas(-1, nama_entitas, [["id_proses", id_pemain]])
									# atur id_proses dengan id_pemain
									pool_entitas[nama_entitas]["id_proses"] = id_pemain
					
					# loop array pool_objek
					if !pool_objek.is_empty():
						var indeks_pool_objek = pool_objek.keys()
						for i_pool_objek in indeks_pool_objek.size(): 
							var nama_objek = indeks_pool_objek[i_pool_objek]
							# cek jarak pemain dengan objek
							var jarak_pemain = pemain[i_pool_pemain]["posisi"].distance_to(pool_objek[nama_objek]["posisi"])
							# pastikan keadaan visibilitas pool
							if cek_visibilitas_pool_objek.get(id_pemain) == null:
								cek_visibilitas_pool_objek[id_pemain] = {}
							if cek_visibilitas_pool_objek[id_pemain].get(nama_objek) == null:
								cek_visibilitas_pool_objek[id_pemain][nama_objek] = "hapus"
							# jika frustum culling diaktifkan dan jarak pemain lebih dari jarak render objek
							if permainan.gunakan_frustum_culling and jarak_pemain > pool_objek[nama_objek]["jarak_render"]:
								# pastikan pemain saat ini tidak mengubah objek
								if pool_objek[nama_objek]["id_pengubah"] != id_pemain:
									# hanya hapus jika pool telah di-spawn
									if cek_visibilitas_pool_objek[id_pemain][nama_objek] == "spawn":
										# rpc hapus pool_objek
										hapus_pool_objek(id_pemain, nama_objek)
										# ubah visibilitas pool agar jangan rpc lagi
										cek_visibilitas_pool_objek[id_pemain][nama_objek] = "hapus"
							# jika jarak pemain kurang dari jarak render objek
							else:
								# hanya spawn jika pool belum di-spawn
								if cek_visibilitas_pool_objek[id_pemain][nama_objek] == "hapus":
									# rpc spawn pool objek
									spawn_pool_objek(id_pemain, nama_objek, pool_objek[nama_objek]["jalur_instance"], pool_objek[nama_objek]["id_pengubah"], pool_objek[nama_objek]["posisi"], pool_objek[nama_objek]["rotasi"], pool_objek[nama_objek]["properti"])
									# ubah visibilitas pool agar jangan rpc lagi
									cek_visibilitas_pool_objek[id_pemain][nama_objek] = "spawn"
					
					# loop array pool_karakter
					if !pool_karakter.is_empty():
						var indeks_pool_karakter = pool_karakter.keys()
						for i_pool_karakter in indeks_pool_karakter.size(): 
							var nama_karakter = indeks_pool_karakter[i_pool_karakter]
							# cek jarak pemain dengan karakter
							var jarak_pemain = pemain[i_pool_pemain]["posisi"].distance_to(pool_karakter[nama_karakter]["posisi"])
							# pastikan keadaan visibilitas pool
							if cek_visibilitas_pool_karakter.get(id_pemain) == null:
								cek_visibilitas_pool_karakter[id_pemain] = {}
							if cek_visibilitas_pool_karakter[id_pemain].get(nama_karakter) == null:
								cek_visibilitas_pool_karakter[id_pemain][nama_karakter] = "hapus"
							# jika jarak pemain lebih dari jarak render karakter
							if jarak_pemain > jarak_render_karakter:
								# pastikan pemain saat ini tidak mengubah karakter
								if pool_karakter[nama_karakter]["id_pengubah"] != id_pemain:
									# cek jika id_proses telah diatur dan pemain saat ini adalah pemroses
									if pool_karakter[nama_karakter]["id_proses"] != -1 and pool_karakter[nama_karakter]["id_proses"] == id_pemain:
										# rpc atur -1 sebagai pemroses karakter ke semua peer
										sinkronkan_kondisi_karakter(-1, nama_karakter, [["id_proses", -1]])
										# atur id_proses dengan -1
										pool_karakter[nama_karakter]["id_proses"] = -1
									# hanya hapus jika pool telah di-spawn
									if cek_visibilitas_pool_karakter[id_pemain][nama_karakter] == "spawn":
										# rpc hapus pool_karakter
										hapus_pool_karakter(id_pemain, nama_karakter)
										# ubah visibilitas pool agar jangan rpc lagi
										cek_visibilitas_pool_karakter[id_pemain][nama_karakter] = "hapus"
							# jika jarak pemain kurang dari jarak render karakter
							else:
								# hanya spawn jika pool belum di-spawn
								if cek_visibilitas_pool_karakter[id_pemain][nama_karakter] == "hapus":
									# rpc spawn pool karakter
									spawn_pool_karakter(id_pemain, nama_karakter, pool_karakter[nama_karakter]["jalur_instance"], pool_karakter[nama_karakter]["id_proses"], pool_karakter[nama_karakter]["posisi"], pool_karakter[nama_karakter]["rotasi"], pool_karakter[nama_karakter]["kondisi"])
									# ubah visibilitas pool agar jangan rpc lagi
									cek_visibilitas_pool_karakter[id_pemain][nama_karakter] = "spawn"
								# cek jika id_proses belum diatur
								if pool_karakter[nama_karakter]["id_proses"] == -1:
									# rpc atur pemain sebagai pemroses karakter ke semua peer
									sinkronkan_kondisi_karakter(-1, nama_karakter, [["id_proses", id_pemain]])
									# atur id_proses dengan id_pemain
									pool_karakter[nama_karakter]["id_proses"] = id_pemain

func buat_koneksi() -> void:
	interface = MultiplayerAPI.create_default_interface()
	peer = ENetMultiplayerPeer.new()
	peer.create_server(10567, jumlah_pemain)
	interface.connect("peer_connected", self._pemain_bergabung)
	interface.connect("peer_disconnected", self._pemain_terputus)
	interface.set_multiplayer_peer(peer)
	get_tree().set_multiplayer(interface)
	#interface.set_root_path(NodePath("/root/dunia"))
	interface.set_refuse_new_connections(false)
	client.id_koneksi = 1
	siarkan_server()
	set_process(true)
	if publik: # koneksi publik
		upnp = UPNP.new()
		var hasil_pencarian = upnp.discover(4000, 2)
		
		# cek apakah adapter mendukung
		if hasil_pencarian == UPNP.UPNP_RESULT_SUCCESS:
			if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
				var map_hasil_udp = upnp.add_port_mapping(10567, 0, "godot_udp", "UDP")
				var map_hasil_tcp = upnp.add_port_mapping(10567, 0, "godot_tcp", "TCP")
				
				# cek kalo port gak bisa di-forward
				if not map_hasil_udp == UPNP.UPNP_RESULT_SUCCESS:
					upnp.add_port_mapping(10567, 0, "", "UDP")
				if not map_hasil_tcp == UPNP.UPNP_RESULT_SUCCESS:
					upnp.add_port_mapping(10567, 0, "", "TCP")
			
			# dapetin ip publik
			ip_publik = upnp.query_external_address()
		else:
			#ip_publik = "ERROR:<"+str(hasil_pencarian)+">"
			ip_publik = "localhost:10567"
			publik = false
	var t_inf_kon = TranslationServer.translate("%buatkoneksi")
	Panku.notify(t_inf_kon % [map, "localhost"])
	Panku.gd_exprenv.register_env("server", self)
func putuskan() -> void:
	interface.set_refuse_new_connections(true)
	hapus_siaran_server()
	if publik: # koneksi publik
		upnp.delete_port_mapping(10567, "UDP")
		upnp.delete_port_mapping(10567, "TCP")
		ip_publik = "<null>"
	peer.close()
	peer = null
	interface.clear()
	interface.set_root_path(NodePath("/root"))
	interface = null
	client.id_koneksi = -44
	pemain_terhubung = 0
	# kompilasi data frame timeline
	set_process(false)
	# - pindahkan timeline["data"] ke variabel baru
	var b_data_timeline = timeline["data"]
	timeline.erase("data")
	# - pindahkan data frame terakhir ke variabel baru
	var b_data_frame = timeline.duplicate()
	# - kosongkan data frame timeline
	timeline.clear()
	# - pindahkan kembali timeline["data"] ke timeline
	timeline["data"] = b_data_timeline
	# - dapatkan nama_file timeline berdasarkan id_timeline
	for i in timeline["data"]["urutan"] - 1:
		var nama_file_timeline = "timeline_%s-%s-%s_%s.timelinepart" % [map, nama, timeline["data"]["id"], str(i+1)]
		# > buka nama_file_timeline lalu set ke tmp_frame
		if FileAccess.file_exists(direktori_cache_replay+"/"+nama_file_timeline): # cegah error jika seandainya file corrupt
			var file = FileAccess.open(direktori_cache_replay+"/"+nama_file_timeline, FileAccess.READ_WRITE)
			var tmp_frame = file.get_var()
			# > merge tmp_frame ke timeline
			timeline.merge(tmp_frame, true)
			# > tutup file nama_file_timeline
			file.close()
			# > hapus file nama_file_timeline
			DirAccess.remove_absolute(direktori_cache_replay+"/"+nama_file_timeline)
	# - pindahkan kembali (merge) frame terakhir ke timeline
	timeline.merge(b_data_frame, true)
	# - hapus id dari timeline["data"]
	timeline["data"].erase("id")
	# - hapus urutan dari timeline["data"]
	timeline["data"].erase("urutan")
	# - simpan timeline ke file
	# > pastikan frame tidak kosong
	if timeline.size() > 10:
		var file = FileAccess.open(file_replay, FileAccess.WRITE)
		var indeks_timeline = timeline.keys()
		# > jangan langsug stor, hapus dulu frame yang kosong!
		for frame in indeks_timeline.size(): 
			if timeline[indeks_timeline[frame]].size() < 1:
				timeline.erase(indeks_timeline[frame])
		indeks_timeline.clear()
		file.store_var(timeline)
		file.close()
	# setup pool
	pool_entitas.clear()
	pool_objek.clear()
	jumlah_entitas = 0
	jumlah_objek = 0
	cek_visibilitas_pemain.clear()
	cek_visibilitas_pool_entitas.clear()
	cek_visibilitas_pool_objek.clear()
	Panku.notify(TranslationServer.translate("%putuskanserver"))
	Panku.gd_exprenv.remove_env("server")
	
func siarkan_server() -> void:
	hapus_siaran_server()
	broadcast = ServerAdvertiser.new()
	broadcast.name = "broadcast server"
	broadcast.broadcastPort = 10568
	broadcast.serverInfo["nama"] = nama
	broadcast.serverInfo["sys"] = permainan.data["sistem"]
	broadcast.serverInfo["map"] = map
	broadcast.serverInfo["jml_pemain"] = pemain_terhubung
	broadcast.serverInfo["max_pemain"] = jumlah_pemain
	permainan.add_child(broadcast)
func hapus_siaran_server() -> void:
	if is_instance_valid(broadcast):
		broadcast.queue_free()

func buat_koneksi_virtual():
	interface = MultiplayerAPI.create_default_interface()
	peer = ENetMultiplayerPeer.new()
	broadcast = ServerAdvertiser.new()
	peer.create_server(10567, 1)
	interface.set_multiplayer_peer(peer)
	get_tree().set_multiplayer(interface)
	interface.set_refuse_new_connections(true)
func putuskan_koneksi_virtual():
	peer.close()
	peer = null
	interface.clear()
	interface.set_root_path(NodePath("/root"))
	interface = null

func spawn_pool_pemain(id_pemain : int, id_spawn_pemain : int, data : Dictionary):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if id_pemain == 1: _spawn_visibilitas_pemain(id_spawn_pemain, data)
		else: rpc_id(id_pemain, "_spawn_visibilitas_pemain", id_spawn_pemain, data)
		print("%s => spawn pool pemain [%s] pada pemain %s" % [permainan.detikKeMenit(Time.get_ticks_msec()), str(id_spawn_pemain), str(id_pemain)])
func spawn_pool_entitas(id_pemain, nama_entitas : String, jalur_instance_entitas, id_pemroses_entitas, posisi_entitas : Vector3, rotasi_entitas : Vector3, kondisi_entitas : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		#Panku.notify("spawn pool entitas [%s] pada pemain %s" % [str(jalur_instance_entitas), str(id_pemain)])
		if id_pemain == 1: _spawn_visibilitas_entitas(jalur_instance_entitas, id_pemroses_entitas, nama_entitas, posisi_entitas, rotasi_entitas, kondisi_entitas)
		else: rpc_id(id_pemain, "_spawn_visibilitas_entitas", jalur_instance_entitas, id_pemroses_entitas, nama_entitas, posisi_entitas, rotasi_entitas, kondisi_entitas)
func spawn_pool_objek(id_pemain, nama_objek : String, jalur_instance_objek, id_pengubah, posisi_objek : Vector3, rotasi_objek : Vector3, properti_objek : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		#Panku.notify("spawn pool objek [%s] pada pemain %s" % [str(jalur_instance_objek), str(id_pemain)])
		if id_pemain == 1: _spawn_visibilitas_objek(jalur_instance_objek, id_pengubah, nama_objek, posisi_objek, rotasi_objek, properti_objek)
		else: rpc_id(id_pemain, "_spawn_visibilitas_objek", jalur_instance_objek, id_pengubah, nama_objek, posisi_objek, rotasi_objek, properti_objek)
func spawn_pool_karakter(id_pemain, nama_karakter : String, jalur_instance_karakter, id_pengubah, posisi_karakter : Vector3, rotasi_karakter : Vector3, kondisi_karakter : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		#Panku.notify("spawn pool karakter [%s] pada pemain %s" % [str(jalur_instance_karakter), str(id_pemain)])
		if id_pemain == 1: _spawn_visibilitas_karakter(jalur_instance_karakter, id_pengubah, nama_karakter, posisi_karakter, rotasi_karakter, kondisi_karakter)
		else: rpc_id(id_pemain, "_spawn_visibilitas_karakter", jalur_instance_karakter, id_pengubah, nama_karakter, posisi_karakter, rotasi_karakter, kondisi_karakter)
func sinkronkan_kondisi_entitas(id_pemain, nama_entitas : String, kondisi_entitas : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if id_pemain == 1:
			_sinkronkan_kondisi_entitas(nama_entitas, kondisi_entitas)
		elif id_pemain == -1:
			_sinkronkan_kondisi_entitas(nama_entitas, kondisi_entitas)
			rpc("_sinkronkan_kondisi_entitas", nama_entitas, kondisi_entitas)
		else:
			rpc_id(id_pemain, "_sinkronkan_kondisi_entitas", nama_entitas, kondisi_entitas)
func sinkronkan_kondisi_objek(id_pemain, nama_objek : String, kondisi_objek : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if id_pemain == 1:
			_sinkronkan_kondisi_objek(nama_objek, kondisi_objek)
		elif id_pemain == -1:
			_sinkronkan_kondisi_objek(nama_objek, kondisi_objek)
			rpc("_sinkronkan_kondisi_objek", nama_objek, kondisi_objek)
		else:
			rpc_id(id_pemain, "_sinkronkan_kondisi_objek", nama_objek, kondisi_objek)
func sinkronkan_kondisi_karakter(id_pemain, nama_karakter : String, kondisi_karakter : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if id_pemain == 1:
			_sinkronkan_kondisi_karakter(nama_karakter, kondisi_karakter)
		elif id_pemain == -1:
			_sinkronkan_kondisi_karakter(nama_karakter, kondisi_karakter)
			rpc("_sinkronkan_kondisi_karakter", nama_karakter, kondisi_karakter)
		else:
			rpc_id(id_pemain, "_sinkronkan_kondisi_karakter", nama_karakter, kondisi_karakter)
func hapus_pool_pemain(id_pemain, id_hapus_pemain):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if id_pemain == 1: _hapus_visibilitas_pemain(id_hapus_pemain)
		else: rpc_id(id_pemain, "_hapus_visibilitas_pemain", id_hapus_pemain)
		print("%s => menghapus pool pemain [%s] pada pemain %s" % [permainan.detikKeMenit(Time.get_ticks_msec()), str(id_hapus_pemain), str(id_pemain)])
func hapus_pool_entitas(id_pemain, nama_entitas : String):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		#Panku.notify("menghapus pool entitas [%s] pada pemain %s" % [nama_entitas, str(id_pemain)])
		if id_pemain == 1: _hapus_visibilitas_entitas(nama_entitas)
		else: rpc_id(id_pemain, "_hapus_visibilitas_entitas", nama_entitas)
func hapus_pool_objek(id_pemain, nama_objek : String):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		#Panku.notify("menghapus pool objek [%s] pada pemain %s" % [nama_objek, str(id_pemain)])
		if id_pemain == 1: _hapus_visibilitas_objek(nama_objek)
		else: rpc_id(id_pemain, "_hapus_visibilitas_objek", nama_objek)
func hapus_pool_karakter(id_pemain, nama_karakter : String):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		#Panku.notify("menghapus pool karakter [%s] pada pemain %s" % [nama_karakter, str(id_pemain)])
		if id_pemain == 1: _hapus_visibilitas_karakter(nama_karakter)
		else: rpc_id(id_pemain, "_hapus_visibilitas_karakter", nama_karakter)
func gunakan_entitas(nama_entitas : String, fungsi : String):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		_gunakan_entitas(nama_entitas, multiplayer.get_unique_id(), fungsi)
	else:
		rpc_id(1, "_gunakan_entitas", nama_entitas, multiplayer.get_unique_id(), fungsi)
func cek_visibilitas_entitas_terhadap_pemain(id_pemain : int, jalur_objek, jarak_render_objek = 100) -> bool:
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		var ref_pemain : Karakter = dunia.get_node_or_null("pemain/"+str(id_pemain))
		var ref_entitas : Node3D  = get_node_or_null(jalur_objek)
		if ref_pemain != null and ref_entitas != null:
			# tentukan jarak dan arahnya
			var arah_pemain = Vector3.BACK.rotated(Vector3.UP, ref_pemain.rotation.y)
			var jarak_pemain = ref_entitas.global_transform.origin.distance_to(ref_pemain.global_transform.origin)
			var jarak_entitas : Vector3 = ref_entitas.global_transform.origin - ref_pemain.global_transform.origin
			
			# normalisasi vektor
			jarak_entitas.y = 0 # kalkulasi secara horizontal, abaikan ketinggian!
			arah_pemain = arah_pemain.normalized()
			jarak_entitas = jarak_entitas.normalized()
			
			# hitung sudut antara vektor
			var dot_product = arah_pemain.dot(jarak_entitas)
			var sudut = rad_to_deg(acos(dot_product))
			
			# periksa apakah jarak pemain cukup dekat atau sudut kurang dari FOV pemain
			if jarak_pemain <= 15: return true
			elif jarak_pemain > (jarak_render_objek + 5): return false
			else: return sudut <= (ref_pemain.get_node("%pandangan").fov / 2) + 5
		else:
			return false
	else:	return false
func dorong_pemain(id_pemain : int, arah_dorong : Vector3):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		_terima_dorongan_pemain_terhadap_pemain(client.id_sesi, id_pemain, arah_dorong)
	else:
		rpc_id(1, "_terima_dorongan_pemain_terhadap_pemain", client.id_sesi, id_pemain, arah_dorong)
func edit_objek(nama_objek : String, fungsi : bool):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		_edit_objek(nama_objek, multiplayer.get_unique_id(), fungsi)
	else:
		rpc_id(1, "_edit_objek", nama_objek, multiplayer.get_unique_id(), fungsi)
func terapkan_percepatan_objek(jalur_objek : String, nilai_percepatan : Vector3):
	_terapkan_percepatan_objek(jalur_objek, nilai_percepatan)
	rpc("_terapkan_percepatan_objek", jalur_objek, nilai_percepatan)
func fungsikan_objek(nama_objek : StringName, nama_fungsi : StringName, parameter : Array = []):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		_fungsikan_objek(nama_objek, nama_fungsi, parameter)
	else:
		rpc_id(1, "_fungsikan_objek", nama_objek, nama_fungsi, parameter)
func hapus_objek(jalur_objek : String) -> void:
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		_hapus_objek(jalur_objek)
	else:
		rpc_id(1, "_hapus_objek", jalur_objek)
func kirim_aset(id_penerima : int, jalur_aset : String, nama_aset : String):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and jalur_aset.length() > 5:
		# 11/11/24 :: kirim aset ke client
		var balik_jalur = jalur_aset.reverse()
		var pecah_format_jalur = balik_jalur.split(".", false, 1)
		var pecah_jalur = balik_jalur.split("/", false, 2)
		var tipe_aset = pecah_jalur[1].reverse()
		var format_aset = pecah_format_jalur[0].reverse()
		var baca_file_aset = FileAccess.open(jalur_aset, FileAccess.READ)
		client.rpc_id(id_penerima, "terima_aset", FileAccess.get_file_as_bytes(jalur_aset), tipe_aset, nama_aset, format_aset)
		baca_file_aset.close()

func _pemain_bergabung(id_pemain):
	# disini tentuin posisi dan rotasi spawn client terus kirim rpc data map ke client
	var pos := Vector2.from_angle(randf() * 2 * PI);
	var posisi = Vector3(
		pos.x * POSISI_SPAWN_RANDOM * randf(), 
		2, 
		pos.y * POSISI_SPAWN_RANDOM * randf()
	)
	var rotasi = Vector3.ZERO
	# cek data pemain, kalo pemain ada di data; pake posisi dan rotasi dari data tersebut
	# kalo pemain gak ada di data, pake posisi dan rotasi dari posisi_spawn
	# kalo posisi_spawn gak ada, pake posisi saat ini (posisi acak) dan rotasi 0
	if dunia.get_node_or_null("posisi_spawn") != null:
		# HACK : kesalahan class akan menimbulkan softlock pada client ketika tetputus pada proses koneksi
		# [mis. dunia.map.get_node_or_null]
		# ini bisa dipake untuk testing client
		posisi = dunia.get_node("posisi_spawn").position
		rotasi = dunia.get_node("posisi_spawn").rotation
	client.rpc_id(
		id_pemain, 
		"gabung_ke_server", 
		nama, 
		map, 
		posisi,
		rotasi
	)
	print("%s => pemain [%s] telah bergabung" % [permainan.detikKeMenit(Time.get_ticks_msec()), id_pemain])
	pemain_terhubung += 1
	siarkan_server()
func _pemain_terputus(id_pemain):
	# Timeline : hapus pemain
	var frame_sekarang = timeline["data"]["frame"]
	if not timeline.has(frame_sekarang): timeline[frame_sekarang] = {}
	timeline[frame_sekarang][id_pemain] = {
		"tipe": "hapus"
	}
	
	# hapus pemain dari daftar pemain
	permainan._hapus_daftar_pemain(id_pemain)
	
	# hapus pemain dari daftar di semua peer
	client.rpc("hapus_pemain", id_pemain)
	
	# hapus pemain dari pengecekan visibilitas
	if cek_visibilitas_pemain.has(id_pemain): cek_visibilitas_pemain.erase(id_pemain)
	
	# 07/07/24 :: loop tiap pemain, reset id dan hapus pool pemain yang terputus
	for idx_pemain in pemain.keys():
		# dapatkan id pemain target
		var id_pemain_target = pemain[idx_pemain]["id_client"]
		
		# pastikan pemain valid
		if id_pemain_target != 0:
			# jika pemain adalah target, reset idnya
			if id_pemain_target == id_pemain: pemain[idx_pemain]["id_client"] = 0
			# hapus visibilitas pemain pada pemain target
			elif cek_visibilitas_pemain.has(id_pemain_target):
				if cek_visibilitas_pemain[id_pemain_target].has(id_pemain):
					cek_visibilitas_pemain[id_pemain_target].erase(id_pemain)
				hapus_pool_pemain(id_pemain_target, id_pemain)
	
	# jika pool pemain spawn, hapus pemain dari dunia
	if dunia.get_node_or_null("pemain/"+str(id_pemain)) != null:
		dunia.get_node("pemain/"+str(id_pemain)).hapus()
	
	# 29/06/24 :: loop pool_objek kemudian reset id_pengubah pada objek yang id_pengubah == id_pemain
	# loop array pool_objek
	if !pool_objek.is_empty():
		var indeks_pool_objek = pool_objek.keys()
		for i_pool_objek in indeks_pool_objek.size():
			# dapatkan objek
			var nama_objek = indeks_pool_objek[i_pool_objek]
			var objek_ = pool_objek[nama_objek]
			# cek id pengubah objek, apakah sama dengan id pemain yang terputus
			if objek_.id_pengubah == id_pemain:
				# rpc atur ulang id_pengubah di semua peer
				sinkronkan_kondisi_objek(-1, nama_objek, [["id_pengubah", 0]])
				# atur ulang id_pengubah
				pool_objek[nama_objek]["id_pengubah"] = 0
				# hentikan loop
				break
	
	# 27/04/25 :: loop pool_entitas kemudian reset id_proses pada entitas yang id_proses == id_pemain
	# loop array pool_entitas
	if !pool_entitas.is_empty():
		var indeks_pool_entitas = pool_entitas.keys()
		for i_pool_entitas in indeks_pool_entitas.size():
			# dapatkan entitas
			var nama_entitas = indeks_pool_entitas[i_pool_entitas]
			var entitas_ = pool_entitas[nama_entitas]
			# cek id pemroses entitas, apakah sama dengan id pemain yang terputus
			if entitas_.id_proses == id_pemain:
				# rpc atur ulang id_proses di semua peer
				sinkronkan_kondisi_entitas(-1, nama_entitas, [["id_proses", -1]])
				# atur ulang id_proses
				pool_entitas[nama_entitas]["id_proses"] = -1
			# atur ulang id kustom misalnya id_pengguna_1
			for indeks_properti in entitas_.kondisi.size():
				if entitas_.kondisi[indeks_properti - 1][0].begins_with("id_") and int(entitas_.kondisi[indeks_properti - 1][1]) == id_pemain:
					# rpc atur ulang id kustom di semua peer
					sinkronkan_kondisi_entitas(-1, nama_entitas, [["kondisi", [[entitas_.kondisi[indeks_properti - 1][0], -1]]]])
					# atur ulang id kustom
					pool_entitas[nama_entitas]["kondisi"][indeks_properti - 1][1] = -1
					print("%s => mengatur properti [%s] pada entitas [%s] dari [%s] menjadi: %s" % [permainan.detikKeMenit(Time.get_ticks_msec()), entitas_.kondisi[indeks_properti - 1][0], nama_entitas, id_pemain, str(pool_entitas[nama_entitas]["kondisi"][indeks_properti - 1][1])])
	
	print("%s => pemain [%s] telah terputus" % [permainan.detikKeMenit(Time.get_ticks_msec()), id_pemain])
	pemain_terhubung -= 1
	siarkan_server()

@rpc("any_peer") func _tambahkan_pemain_ke_dunia(id_pemain, id_sesi, data_pemain):
	if permainan.koneksi == permainan.MODE_KONEKSI.SERVER:
		# INFO : (5b2) tambahkan pemain client ke dunia
		# muat sesi dari pool (jika tersedia)
		if pemain.has(id_sesi):
			# terapkan data sesi
			data_pemain["posisi"] = pemain[id_sesi]["posisi"]
			data_pemain["rotasi"] = pemain[id_sesi]["rotasi"]
			
			# timpa data sesi
			pemain[id_sesi]["id_client"] = id_pemain
			pemain[id_sesi]["nama"] = data_pemain["nama"]
			pemain[id_sesi]["model"]["gender"]			= data_pemain["gender"]
			pemain[id_sesi]["model"]["alis"]			= data_pemain["alis"]
			pemain[id_sesi]["model"]["garis_mata"]		= data_pemain["garis_mata"]
			pemain[id_sesi]["model"]["mata"]			= data_pemain["mata"]
			pemain[id_sesi]["model"]["warna_mata"]		= data_pemain["warna_mata"]
			pemain[id_sesi]["model"]["rambut"]			= data_pemain["rambut"]
			pemain[id_sesi]["model"]["warna_rambut"]	= data_pemain["warna_rambut"]
			pemain[id_sesi]["model"]["baju"]			= data_pemain["baju"]
			pemain[id_sesi]["model"]["warna_baju"]		= data_pemain["warna_baju"]
			pemain[id_sesi]["model"]["celana"]			= data_pemain["celana"]
			pemain[id_sesi]["model"]["warna_celana"]	= data_pemain["warna_celana"]
			pemain[id_sesi]["model"]["sepatu"]			= data_pemain["sepatu"]
			pemain[id_sesi]["model"]["warna_sepatu"]	= data_pemain["warna_sepatu"]
			
			# reset data sesi
			pemain[id_sesi]["kondisi"]["mode_gestur"]	= "berdiri"
			pemain[id_sesi]["kondisi"]["arah_gerakan"]	= Vector3.ZERO
			pemain[id_sesi]["kondisi"]["mode_menyerang"]= "a"
			pemain[id_sesi]["kondisi"]["arah_pandangan"]= Vector2.ZERO
			pemain[id_sesi]["kondisi"]["gestur_jongkok"]= 0.0
		# tambahkan ke pool
		else:
			pemain[id_sesi] = {
				"id_client": id_pemain,
				"nama": 	data_pemain["nama"],
				"posisi":	data_pemain["posisi"],
				"rotasi":	data_pemain["rotasi"],
				"model": {
					"gender":		data_pemain["gender"],
					"alis":			data_pemain["alis"],
					"garis_mata":	data_pemain["garis_mata"],
					"mata":			data_pemain["mata"],
					"warna_mata":	data_pemain["warna_mata"],
					"rambut":		data_pemain["rambut"],
					"warna_rambut":	data_pemain["warna_rambut"],
					"baju":			data_pemain["baju"],
					"warna_baju":	data_pemain["warna_baju"],
					"celana":		data_pemain["celana"],
					"warna_celana":	data_pemain["warna_celana"],
					"sepatu":		data_pemain["sepatu"],
					"warna_sepatu":	data_pemain["warna_sepatu"]
				},
				"kondisi":		{
					"arah_gerakan": 	Vector3.ZERO,
					"arah_pandangan":	Vector2.ZERO,
					"mode_gestur":		"berdiri",
					"pose_duduk":		"normal",
					"gestur_jongkok":	0.0,
					"mode_menyerang": 	"a"
				}
			}
		# tambahkan ke client
		if not headless: rpc_id(id_pemain, "_tambahkan_pemain_ke_dunia", 1, id_sesi, permainan.data)
		# 09/07/24 :: buat daftar pemain kemudian kirim ke client yang bergabung
		var daftar_pemain : Dictionary = {}
		for dt_pemain in permainan._dapatkan_daftar_pemain():
			daftar_pemain[dt_pemain.name] = {
				"nama":		dt_pemain.nama,
				"sistem":	dt_pemain.sistem,
				"id_sys":	dt_pemain.name,
				"gender":	dt_pemain.karakter,
				"gambar":	dt_pemain.gambar
			}
		client.rpc_id(id_pemain, "tambahkan_pemain", daftar_pemain)
		# tambahkan ke daftar pemain
		permainan._tambahkan_pemain(id_pemain, data_pemain)
		client.rpc("tambah_pemain", id_pemain, data_pemain)
		print("%s => tambah pemain [%s] ke dunia" % [permainan.detikKeMenit(Time.get_ticks_msec()), id_pemain])
@rpc("any_peer") func _terima_suara_pemain(id_pemain : int, data_suara : PackedByteArray, ukuran_buffer : int):
	print("pemain [%s] berbicara (%s)" % [str(id_pemain), str(ukuran_buffer)])
	# dekompresi dan simpan data suara ke array yang kemudian dimainkan pada thread
	var tmp_data_suara : PackedByteArray = data_suara.decompress(ukuran_buffer, FileAccess.COMPRESSION_ZSTD)
	dunia.get_node("pemain/"+str(id_pemain)+"/suara").array_suara.append(tmp_data_suara)
	# mainkan suara *
	dunia.get_node("pemain/"+str(id_pemain)+"/suara").bicara()
@rpc("any_peer") func _terima_pesan_pemain(id_pemain : String, pesan : String):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		# [14:42:58] [color="ff00aa"]uswa[/color] : aku sayang banget sama kamu >u<
		var waktu = Time.get_datetime_dict_from_system() # { "year": 2023, "month": 9, "day": 25, "weekday": 1, "hour": 11, "minute": 28, "second": 57, "dst": false }
		var jam   = str(waktu["hour"]);
		var menit = str(waktu["minute"]);
		var detik = str(waktu["second"])
		if waktu["hour"] 	< 10: jam 	= "0"+str(waktu["hour"])
		if waktu["minute"]	< 10: menit = "0"+str(waktu["minute"])
		if waktu["second"] 	< 10: detik = "0"+str(waktu["second"])
		# TODO : warna nama pemain berdasarkan warna pemain
		var teks = "[%s:%s:%s] [color=\"%s\"]%s[/color] : %s" % [
			jam, menit, detik,
			"ff80ff",
			pemain[id_pemain]["nama"],
			pesan
		]
		pesan = teks
		rpc("_terima_pesan_pemain", id_pemain, pesan)
	permainan._tampilkan_pesan(pesan)
@rpc("any_peer") func _terima_dorongan_pemain_terhadap_pemain(id_pemain_pendorong : String, id_pemain_didorong : int, arah_dorongan : Vector3):
	# 12/07/24 :: dorong pemain lain
	# * Couple N - Dreamland  ~  Couple N - Love Trip *
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		var id_pendorong = pemain[id_pemain_pendorong]["id_client"]
		if cek_visibilitas_pemain.has(id_pendorong) and cek_visibilitas_pemain[id_pendorong].has(id_pemain_didorong) and cek_visibilitas_pemain[id_pendorong][id_pemain_didorong] == "spawn":
			var indeks_pool_pemain = pemain.keys()
			for i_pool_pemain in indeks_pool_pemain:
				var id_didorong = pemain[i_pool_pemain]["id_client"]
				if id_didorong == id_pemain_didorong and pemain[id_pemain_pendorong]["posisi"].distance_to(pemain[i_pool_pemain]["posisi"]) < 3:
					#Panku.notify("Dreamcatcher")
					if id_pemain_didorong == client.id_koneksi:
						_terima_dorongan_dari_pemain(id_pendorong, arah_dorongan)
					else:
						rpc_id(id_pemain_didorong, "_terima_dorongan_dari_pemain", id_pendorong, arah_dorongan)
					break
				#else:
				#	Panku.notify("Kirara Magic - Sweet Dream")
@rpc("any_peer") func _tambahkan_entitas(jalur_skena : String, posisi : Vector3, rotasi : Vector3, properti : Array) -> void:
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if load(jalur_skena) != null:
			jumlah_entitas += 1
			var nama_entitas : StringName = "entitas_"+str(jumlah_entitas)
			# INFO : tambahkan entitas ke array pool_entitas
			pool_entitas[nama_entitas] = {
				"jalur_instance": jalur_skena,
				"id_proses" : -1,
				"id_pengubah": 0,
				"posisi"	: posisi,
				"rotasi"	: rotasi,
				"kondisi"	: properti
			}
			# Timeline : spawn entitas
			if not mode_replay:
				if not timeline.has(timeline["data"]["frame"]):
					timeline[timeline["data"]["frame"]] = {}
				timeline[timeline["data"]["frame"]][nama_entitas] = {
					"tipe": 		"spawn",
					"tipe_objek":	"entitas",
					"sumber": 		jalur_skena,
					"posisi":		posisi,
					"rotasi":		rotasi,
					"properti":		properti,
				}
		else: push_error("[Galat] entitas %s tidak ditemukan" % [jalur_skena]); Panku.notify("404 : Objek tak ditemukan [%s]" % [jalur_skena])
	else: push_error("[Galat] fungsi [tambahkan_entitas] hanya dapat dipanggil pada server"); Panku.notify("403 : Terlarang")
@rpc("any_peer") func _tambahkan_objek(jalur_skena : String, posisi : Vector3, rotasi : Vector3, jarak_render : int, properti : Array) -> void:
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if load(jalur_skena) != null:
			jumlah_objek += 1
			var nama_objek : StringName = "objek_"+str(jumlah_objek)
			# INFO : tambahkan objek ke array pool_objek
			pool_objek[nama_objek] = {
				"jarak_render"	: jarak_render,
				"jalur_instance": jalur_skena,
				"id_pengubah": 0,
				"posisi"	: posisi,
				"rotasi"	: rotasi,
				"properti"	: properti
			}
			# Timeline : spawn objek
			if not mode_replay:
				if not timeline.has(timeline["data"]["frame"]):
					timeline[timeline["data"]["frame"]] = {}
				timeline[timeline["data"]["frame"]][nama_objek] = {
					"tipe": 		"spawn",
					"tipe_objek":	"objek",
					"sumber": 		jalur_skena,
					"posisi":		posisi,
					"rotasi":		rotasi,
					"properti":		properti,
				}
		else: push_error("[Galat] objek %s tidak ditemukan" % [jalur_skena]); Panku.notify("404 : Objek tak ditemukan [%s]" % [jalur_skena])
	else: push_error("[Galat] fungsi [tambahkan_objek] hanya dapat dipanggil pada server"); Panku.notify("403 : Terlarang")
@rpc("any_peer") func _tambahkan_karakter(jalur_skena : String, posisi : Vector3, rotasi : Vector3, kondisi : Array) -> void:
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if load(jalur_skena) != null:
			jumlah_karakter += 1
			var nama_karakter : StringName = "karakter_"+str(jumlah_karakter)
			# INFO : tambahkan karakter ke array pool_karakter
			pool_karakter[nama_karakter] = {
				"jalur_instance": jalur_skena,
				"id_proses": -1,
				"id_pengubah": 0,
		 		"posisi" : posisi,
		 		"rotasi" : rotasi,
				"kondisi": kondisi
			}
			# Timeline : spawn karakter
			if not mode_replay:
				if not timeline.has(timeline["data"]["frame"]):
					timeline[timeline["data"]["frame"]] = {}
				timeline[timeline["data"]["frame"]][nama_karakter] = {
					"tipe": 		"spawn",
					"tipe_objek":	"karakter",
					"sumber": 		jalur_skena,
					"posisi":		posisi,
					"rotasi":		rotasi,
					"properti":		kondisi,
				}
		else: push_error("[Galat] karakter %s tidak ditemukan" % [jalur_skena]); Panku.notify("404 : Karakter tak ditemukan [%s]" % [jalur_skena])
	else: push_error("[Galat] fungsi [tambahkan_karakter] hanya dapat dipanggil pada server"); Panku.notify("403 : Terlarang")
@rpc("any_peer") func _gunakan_entitas(nama_entitas : String, id_pengguna : int, fungsi : String):
	var t_entitas = dunia.get_node_or_null("entitas/" + nama_entitas)
	if t_entitas != null and t_entitas.has_method(fungsi):
		t_entitas.call(fungsi, id_pengguna)
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and pool_entitas.get(nama_entitas) != null:
		rpc("_gunakan_entitas", nama_entitas, id_pengguna, fungsi)
@rpc("any_peer") func _fungsikan_objek(nama_objek : String, nama_fungsi : StringName, parameter : Array):
	var objek_difungsikan = dunia.get_node_or_null("objek/" + nama_objek)
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if nama_fungsi == "pindahkan" and parameter.size() > 0 and parameter[0] is Vector3:
			_sesuaikan_properti_objek(
				pool_objek[nama_objek]["id_pengubah"],
				nama_objek,
				[
					["position", pool_objek[nama_objek]["posisi"] + parameter[0]]
				]
			)
			return
		elif nama_fungsi == "berbunyi" and parameter.size() == 1:
			_sesuaikan_properti_objek(
				pool_objek[nama_objek]["id_pengubah"],
				nama_objek,
				[
					["audio", parameter[0]]
				]
			)
			return
		elif (nama_fungsi == "buka" or nama_fungsi == "tutup") and parameter.size() == 0:
			var _tmp_kondisi : bool
			if nama_fungsi == "buka": _tmp_kondisi = true
			_sesuaikan_properti_objek(
				pool_objek[nama_objek]["id_pengubah"],
				nama_objek,
				[
					["terbuka", _tmp_kondisi]
				]
			)
			return
	if objek_difungsikan != null:
		var panggil_fungsi : Callable
		if objek_difungsikan.has_method(nama_fungsi):
			panggil_fungsi = Callable(objek_difungsikan, nama_fungsi)
		elif objek_difungsikan.has_node("kode_ubahan") and objek_difungsikan.get_node("kode_ubahan").has_method(nama_fungsi):
			panggil_fungsi = Callable(objek_difungsikan.get_node("kode_ubahan"), nama_fungsi)
		if panggil_fungsi != null:
			for nilai_parameter in parameter.size():
				panggil_fungsi = panggil_fungsi.bind(
					parameter[
						(parameter.size() - 1) - nilai_parameter
					]
				)
			panggil_fungsi.call()
@rpc("any_peer") func _edit_objek(nama_objek, id_pengubah, fungsi, tampilkan_ui = true):
	var jalur_objek = ""
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if pool_entitas.has(nama_objek):
			jalur_objek = "/root/dunia/entitas/"
			if pool_entitas[nama_objek]["id_pengubah"] == id_pengubah:
				if !fungsi:
					# rpc atur ulang id_pengubah di semua peer
					sinkronkan_kondisi_entitas(-1, nama_objek, [
						["id_proses", -1],
						["id_pengubah", 0]
					])
					# atur ulang id_pengubah
					pool_entitas[nama_objek]["id_pengubah"] = 0
					# atur ulang id_proses
					pool_entitas[nama_objek]["id_proses"] = -1
			elif pool_entitas[nama_objek]["id_pengubah"] == 0:
				if fungsi:
					# cek properti pada entitas tertentu untuk membatalkan pengeditan objek
					if pool_entitas[nama_objek].has("kondisi"):
						var batalkan_pengeditan = false
						var cek_sub_kondisi : Dictionary
						for sub_kondisi in pool_entitas[nama_objek]["kondisi"].size():
							cek_sub_kondisi[pool_entitas[nama_objek]["kondisi"][sub_kondisi][0]] = sub_kondisi
						# 15/09/24 :: deteksi dan cegah pengeditan pada kendaraan yang sedang dikemudikan
						if cek_sub_kondisi.has("engine_force") and cek_sub_kondisi.has("id_pengemudi"):
							#Panku.notify("mengedit kendaraan")
							#Panku.notify("pengemudi : "+str(pool_entitas[nama_objek]["kondisi"][cek_sub_kondisi["id_pengemudi"]]))
							if pool_entitas[nama_objek]["kondisi"][cek_sub_kondisi["id_pengemudi"]][1] != -1: batalkan_pengeditan = true
						cek_sub_kondisi.clear()
						if batalkan_pengeditan: return
					# rpc atur id_pengubah sebagai pemroses entitas dan pengubah objek ke semua peer
					sinkronkan_kondisi_entitas(-1, nama_objek, [
						["id_proses", id_pengubah],
						["id_pengubah", id_pengubah]
					])
					# atur id_pengubah dengan id_pengubah
					pool_entitas[nama_objek]["id_pengubah"] = id_pengubah
					# atur id_proses dengan id_pengubah
					pool_entitas[nama_objek]["id_proses"] = id_pengubah
			else: return
		elif pool_objek.has(nama_objek):
			jalur_objek = "/root/dunia/objek/"
			if pool_objek[nama_objek]["id_pengubah"] == id_pengubah:
				if !fungsi:
					# rpc atur ulang id_pengubah di semua peer
					sinkronkan_kondisi_objek(-1, nama_objek, [["id_pengubah", 0]])
					# atur ulang id_pengubah
					pool_objek[nama_objek]["id_pengubah"] = 0
			elif pool_objek[nama_objek]["id_pengubah"] == 0:
				if fungsi:
					# rpc atur id_pengubah sebagai pengubah objek ke semua peer
					sinkronkan_kondisi_objek(-1, nama_objek, [["id_pengubah", id_pengubah]])
					# atur id_pengubah dengan id_pengubah
					pool_objek[nama_objek]["id_pengubah"] = id_pengubah
			else: return
		elif pool_karakter.has(nama_objek):
			jalur_objek = "/root/dunia/karakter/"
			if pool_karakter[nama_objek]["id_pengubah"] == id_pengubah:
				if !fungsi:
					# rpc atur ulang id_pengubah di semua peer
					sinkronkan_kondisi_karakter(-1, nama_objek, [["id_pengubah", 0]])
					# atur ulang id_pengubah
					pool_karakter[nama_objek]["id_pengubah"] = 0
			elif pool_karakter[nama_objek]["id_pengubah"] == 0:
				if fungsi:
					# rpc atur id_pengubah sebagai pengubah karakter ke semua peer
					sinkronkan_kondisi_karakter(-1, nama_objek, [["id_pengubah", id_pengubah]])
					# atur id_pengubah dengan id_pengubah
					pool_karakter[nama_objek]["id_pengubah"] = id_pengubah
			else: return
		
		if tampilkan_ui:
			# TODO : kirim properti kustom yang bisa di-edit mis: skala, warna, dll..
			if id_pengubah == 1: 		 client.edit_objek(fungsi, jalur_objek+nama_objek)
			else: client.rpc_id(id_pengubah, "edit_objek", fungsi, jalur_objek+nama_objek)
@rpc("any_peer") func _terapkan_percepatan_objek(jalur_objek : String, nilai_percepatan : Vector3):
	var t_objek = get_node_or_null(jalur_objek)
	if t_objek != null and t_objek.get("linear_velocity") != null:
		var t_percepatan : Vector3 = t_objek.linear_velocity + nilai_percepatan
		t_objek.set_linear_velocity(t_percepatan)
		#Panku.notify("mengatur percepatan ["+str(nilai_percepatan)+"] pada $"+jalur_objek)
@rpc("any_peer") func _sesuaikan_kondisi_pemain(id_sesi_pemain : String, id_pemain : int, properti_kondisi : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if pemain.has(id_sesi_pemain) and pemain[id_sesi_pemain]["id_client"] == id_pemain:
			var r_melompat = false
			var r_menyerang = false
			# atur kondisi di pool
			for kondisi_pemain in properti_kondisi:
				if kondisi_pemain[0] == "posisi":			pemain[id_sesi_pemain]["posisi"] = kondisi_pemain[1]
				elif kondisi_pemain[0] == "rotasi":			pemain[id_sesi_pemain]["rotasi"] = kondisi_pemain[1]
				elif kondisi_pemain[0] == "mati":			pemain[id_sesi_pemain]["kondisi"]["mati"] = kondisi_pemain[1]
				elif kondisi_pemain[0] == "pose_duduk":		pemain[id_sesi_pemain]["kondisi"]["pose_duduk"] = kondisi_pemain[1]
				elif kondisi_pemain[0] == "mode_gestur":	pemain[id_sesi_pemain]["kondisi"]["mode_gestur"] = kondisi_pemain[1]
				elif kondisi_pemain[0] == "arah_gerakan":	pemain[id_sesi_pemain]["kondisi"]["arah_gerakan"] = kondisi_pemain[1]
				elif kondisi_pemain[0] == "arah_pandangan":	pemain[id_sesi_pemain]["kondisi"]["arah_pandangan"] = kondisi_pemain[1]
				elif kondisi_pemain[0] == "gestur_jongkok":	pemain[id_sesi_pemain]["kondisi"]["gestur_jongkok"] = kondisi_pemain[1]
				elif kondisi_pemain[0] == "mode_menyerang":	pemain[id_sesi_pemain]["kondisi"]["mode_menyerang"] = kondisi_pemain[1]
				elif kondisi_pemain[0] == "arah_terserang":	pemain[id_sesi_pemain]["kondisi"]["arah_terserang"] = kondisi_pemain[1]
				elif kondisi_pemain[0] == "melompat":		r_melompat = kondisi_pemain[1]
				elif kondisi_pemain[0] == "menyerang":		r_menyerang = kondisi_pemain[1]
			# rpc sinkronkan kondisi id_pemain ke semua pemain yang spawn id_pemain
			if cek_visibilitas_pemain.has(id_pemain):
				for id_pemain_target in cek_visibilitas_pemain[id_pemain]:
					if cek_visibilitas_pemain[id_pemain][id_pemain_target] == "spawn":
						# rpc ke id_pemain_target
						if id_pemain_target == 1:
							_sinkronkan_kondisi_pemain(id_pemain, properti_kondisi)
						# rpc ke pemain yang aktif
						elif id_pemain_target != 0:
							rpc_id(id_pemain_target, "_sinkronkan_kondisi_pemain", id_pemain, properti_kondisi)
			# Timeline : sinkronkan pemain (rekam)
			if not mode_replay:
				# dapatkan waktu frame saat ini
				var frame_sekarang = timeline["data"]["frame"]
				# jika frame saat ini belum ada di timeline, buat data kosong
				if not timeline.has(frame_sekarang): timeline[frame_sekarang] = {}
				# pastikan frame saat ini belum berisi data pemain
				if timeline[frame_sekarang].has(id_pemain): return
				# set frame saat ini ke timeline
				timeline[frame_sekarang][id_pemain] = {
					"tipe": 	"sinkron",
					"posisi":	pemain[id_sesi_pemain]["posisi"],
					"rotasi":	Vector3(rad_to_deg(pemain[id_sesi_pemain]["rotasi"].x), rad_to_deg(pemain[id_sesi_pemain]["rotasi"].y), rad_to_deg(pemain[id_sesi_pemain]["rotasi"].z)),
					"skala":	Vector3(1, 1, 1), # asumsikan skala pemain tidak pernah berubah
					"kondisi":	{
						"arah_gerakan": 	Vector2(-pemain[id_sesi_pemain]["kondisi"]["arah_gerakan"].x, pemain[id_sesi_pemain]["kondisi"]["arah_gerakan"].z / 2),
						"arah_x_pandangan": pemain[id_sesi_pemain]["kondisi"]["arah_pandangan"].x,
						"arah_y_pandangan": pemain[id_sesi_pemain]["kondisi"]["arah_pandangan"].y,
						"gestur":			pemain[id_sesi_pemain]["kondisi"]["mode_gestur"],
						"pose_duduk":		pemain[id_sesi_pemain]["kondisi"]["pose_duduk"],
						"gestur_jongkok":	pemain[id_sesi_pemain]["kondisi"]["gestur_jongkok"],
						"mode_menyerang": 	pemain[id_sesi_pemain]["kondisi"]["mode_menyerang"],
						"lompat":			r_melompat,
						"menyerang": 		r_menyerang,
					}
				}
				# optimasi
				# > kalo data sama dengan frame sebelumnya, hapus kondisi pemain dari frame sebelumnya untuk menghemat penggunaan memori
				# - cek apakah frame sebelumnya telah tersimpan di pool
				if !pemain[id_sesi_pemain].has("cek_frame"):
					pemain[id_sesi_pemain]["cek_frame"] = 0
				if timeline.has(pemain[id_sesi_pemain]["cek_frame"]) and timeline[pemain[id_sesi_pemain]["cek_frame"]].has(id_pemain):
					var data_frame_sebelumnya : String = JSON.stringify(timeline[pemain[id_sesi_pemain]["cek_frame"]][id_pemain], "", true, true)
					var data_frame_saat_ini : String = JSON.stringify(timeline[frame_sekarang][id_pemain], "", true, true)
					# - jika frame saat ini sama dengan frame sebelumnya, hapus frame sebelumnya
					if data_frame_saat_ini == data_frame_sebelumnya:
						timeline[pemain[id_sesi_pemain]["cek_frame"]].erase(id_pemain)
				# - set frame sekarang untuk di-cek pada frame selanjutnya
				pemain[id_sesi_pemain]["cek_frame"] = frame_sekarang
@rpc("any_peer") func _sesuaikan_posisi_entitas(nama_entitas : String, id_pemain : int):
	# kirim posisi entitas ke client kalau posisi di client de-sync
	var t_entitas = dunia.get_node_or_null("entitas/" + nama_entitas)
	if t_entitas != null:
		client.rpc_id(id_pemain, "dapatkan_posisi_entitas", nama_entitas, t_entitas.global_transform.origin, t_entitas.rotation_degrees)
	else:
		client.rpc_id(id_pemain, "dapatkan_posisi_entitas", nama_entitas, pool_entitas[nama_entitas]["posisi"], pool_entitas[nama_entitas]["rotasi"])
@rpc("any_peer") func _sesuaikan_kondisi_entitas(id_pengatur : int, nama_entitas : String, kondisi_entitas : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and pool_entitas[nama_entitas]["id_proses"] == id_pengatur:
		for p in kondisi_entitas.size():
			if kondisi_entitas[p][0] == "position":		pool_entitas[nama_entitas]["posisi"] = kondisi_entitas[p][1]
			elif kondisi_entitas[p][0] == "rotation":	pool_entitas[nama_entitas]["rotasi"] = kondisi_entitas[p][1]
			elif kondisi_entitas[p][0] == "kondisi":
				for k in kondisi_entitas[p][1].size():
					for kp in pool_entitas[nama_entitas]["kondisi"].size():
						if pool_entitas[nama_entitas]["kondisi"][kp - 1][0] == kondisi_entitas[p][1][k - 1][0]:
							pool_entitas[nama_entitas]["kondisi"][kp - 1][1] = kondisi_entitas[p][1][k - 1][1]
			elif pool_entitas[nama_entitas].get(kondisi_entitas[p][0]) != null:
				pool_entitas[nama_entitas][kondisi_entitas[p][0]] = kondisi_entitas[p][1]
		# Timeline : sinkronkan entitas (rekam)
		if not mode_replay:
			# dapatkan waktu frame saat ini
			var frame_sekarang = timeline["data"]["frame"]
			# jika frame saat ini belum ada di timeline, buat data kosong
			if not timeline.has(frame_sekarang): timeline[frame_sekarang] = {}
			# set frame saat ini ke timeline
			timeline[frame_sekarang][nama_entitas] = {
				"tipe": 		"sinkron",
				"posisi":		pool_entitas[nama_entitas]["posisi"],
				"rotasi":		pool_entitas[nama_entitas]["rotasi"],
				"properti":		pool_entitas[nama_entitas]["kondisi"]
			}
			# optimasi
			# - cek apakah frame sebelumnya telah tersimpan di pool
			if !pool_entitas[nama_entitas].has("cek_frame"):
				pool_entitas[nama_entitas]["cek_frame"] = []
			else:
				# - set frame sekarang untuk di-cek pada frame saat ini dan frame selanjutnya
				pool_entitas[nama_entitas]["cek_frame"].append(frame_sekarang)
				# - pastikan entitas tersimpan pada frame sebelumnya
				if pool_entitas[nama_entitas]["cek_frame"].size() > 0 and (timeline.has(pool_entitas[nama_entitas]["cek_frame"][0]) and timeline[pool_entitas[nama_entitas]["cek_frame"][0]].has(nama_entitas)):
					# - lakukan pemeriksaan -> jika frame saat ini sama dengan 3 frame sebelumnya, hapus frame sebelumnya
					if pool_entitas[nama_entitas]["cek_frame"].size() >= 3:
						# dapatkan nomor urut frame 3 frame terakhir
						var tiga_frame_terakhir = pool_entitas[nama_entitas]["cek_frame"].slice(-3)
						# lewati pemeriksaan jika entitas tidak tersimpan pada ketiga frame terakhir
						if !timeline[tiga_frame_terakhir[0]].has(nama_entitas): pass
						elif !timeline[tiga_frame_terakhir[1]].has(nama_entitas): pass
						elif !timeline[tiga_frame_terakhir[2]].has(nama_entitas): pass
						else:
							# ubah data frame menjadi string untuk pengecekan yang akurat
							var data_frame_1 : String = JSON.stringify(timeline[tiga_frame_terakhir[0]][nama_entitas], "", true, true)
							var data_frame_2 : String = JSON.stringify(timeline[tiga_frame_terakhir[1]][nama_entitas], "", true, true)
							var data_frame_3 : String = JSON.stringify(timeline[tiga_frame_terakhir[2]][nama_entitas], "", true, true)
							# - bandingkan frame saat ini dengan frame sebelumnya
							if data_frame_1 == data_frame_2 and data_frame_2 == data_frame_3:
								timeline[tiga_frame_terakhir[1]].erase(nama_entitas)
		# kirim ke semua peer yang di-spawn kecuali id_pengatur!
		for idx_pemain in pemain.keys():
			# dapatkan id pemain target
			var id_pemain_target = pemain[idx_pemain]["id_client"]
			# dapatkan id penyinkron
			var id_penyinkron = multiplayer.get_remote_sender_id() if multiplayer.get_remote_sender_id() != 0 else 1
			# pastikan pemain valid dan pemain bukan yang menyinkronkan kondisi
			if id_pemain_target != 0 and id_pemain_target != id_penyinkron:
				if cek_visibilitas_pool_entitas.has(id_pemain_target) and cek_visibilitas_pool_entitas[id_pemain_target][nama_entitas] == "spawn":
					sinkronkan_kondisi_entitas(id_pemain_target, nama_entitas, kondisi_entitas)
	else:
		push_error("[Galat] tidak dapat menyesuaikan kondisi entitias peer %s dari peer %s. kesalahan akses!" % [str(pool_entitas[nama_entitas]["id_proses"]), str(id_pengatur)])
@rpc("any_peer") func _sesuaikan_properti_objek(id_pengatur : int, nama_objek : String, properti_objek : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and pool_objek[nama_objek]["id_pengubah"] == id_pengatur:
		for p in properti_objek.size():
			if properti_objek[p][0] == "position":		pool_objek[nama_objek]["posisi"] = properti_objek[p][1]
			elif properti_objek[p][0] == "rotation":	pool_objek[nama_objek]["rotasi"] = properti_objek[p][1]
			elif pool_objek[nama_objek].get(properti_objek[p][0]) != null:
				pool_objek[nama_objek][properti_objek[p][0]] = properti_objek[p][1]
			else:
				for k in pool_objek[nama_objek]["properti"].size():
					if pool_objek[nama_objek]["properti"][k][0] == properti_objek[p][0]:
						pool_objek[nama_objek]["properti"][k][1] = properti_objek[p][1]
		# Timeline : sinkronkan objek (rekam)
		if not mode_replay:
			if not timeline.has(server.timeline["data"]["frame"]):
				timeline[server.timeline["data"]["frame"]] = {}
			timeline[server.timeline["data"]["frame"]][nama_objek] = {
				"tipe": 		"sinkron",
				"posisi":		pool_objek[nama_objek]["posisi"],
				"rotasi":		pool_objek[nama_objek]["rotasi"],
				"properti":		pool_objek[nama_objek]["properti"],
			}
		# kirim ke semua peer yang di-spawn kecuali id_pengatur!
		for idx_pemain in pemain.keys():
			if pemain[idx_pemain]["id_client"] != 0 and pemain[idx_pemain]["id_client"] != id_pengatur:
				if cek_visibilitas_pool_objek[pemain[idx_pemain]["id_client"]][nama_objek] == "spawn":
					sinkronkan_kondisi_objek(pemain[idx_pemain]["id_client"], nama_objek, properti_objek)
@rpc("any_peer") func _sesuaikan_kondisi_karakter(id_pengatur : int, nama_karakter : String, kondisi_karakter : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if pool_karakter[nama_karakter]["id_proses"] == id_pengatur or pool_karakter[nama_karakter]["id_pengubah"] == id_pengatur:
			for p in kondisi_karakter.size():
				if kondisi_karakter[p][0] == "position":		pool_karakter[nama_karakter]["posisi"] = kondisi_karakter[p][1]
				elif kondisi_karakter[p][0] == "rotation":		pool_karakter[nama_karakter]["rotasi"] = kondisi_karakter[p][1]
				elif pool_karakter[nama_karakter].get(kondisi_karakter[p][0]) != null:
					pool_karakter[nama_karakter][kondisi_karakter[p][0]] = kondisi_karakter[p][1]
				else:
					for k in pool_karakter[nama_karakter]["kondisi"].size():
						if pool_karakter[nama_karakter]["kondisi"][k][0] == kondisi_karakter[p][0]:
							pool_karakter[nama_karakter]["kondisi"][k][1] = kondisi_karakter[p][1]
			# Timeline : sinkronkan karakter (rekam)
			if not mode_replay:
				if not timeline.has(server.timeline["data"]["frame"]):
					timeline[server.timeline["data"]["frame"]] = {}
				timeline[server.timeline["data"]["frame"]][nama_karakter] = {
					"tipe": 		"sinkron",
					"posisi":		pool_karakter[nama_karakter]["posisi"],
					"rotasi":		pool_karakter[nama_karakter]["rotasi"],
					"kondisi":		pool_karakter[nama_karakter]["kondisi"],
				}
			# kirim ke semua peer yang di-spawn kecuali id_pengatur!
			for idx_pemain in pemain.keys():
				if pemain[idx_pemain]["id_client"] != 0 and pemain[idx_pemain]["id_client"] != id_pengatur:
					if cek_visibilitas_pool_karakter.has(pemain[idx_pemain]["id_client"]) and cek_visibilitas_pool_karakter[pemain[idx_pemain]["id_client"]].has(nama_karakter):
						if cek_visibilitas_pool_karakter[pemain[idx_pemain]["id_client"]][nama_karakter] == "spawn":
							sinkronkan_kondisi_karakter(pemain[idx_pemain]["id_client"], nama_karakter, kondisi_karakter)
	else: push_error("penyesuaian kondisi karakter hanya dapat dilakukan pada server!")
@rpc("any_peer") func _kirim_map(id_pemain : int):						# 11/11/24 :: kirim map ke pemain tertentu
	if map.substr(0,1) == "@" and ResourceLoader.exists("%s/%s.tscn" % [Konfigurasi.direktori_map, map.substr(1)]):
		kirim_aset(id_pemain, "%s/%s.tscn" % [Konfigurasi.direktori_map, map.substr(1)], map.substr(1))
@rpc("any_peer") func _kirim_aset(id_aset : String, id_pemain : int):	# 12/11/24 :: kirim aset tertentu ke pemain tertentu
	if permainan.daftar_aset.has(id_aset) and ResourceLoader.exists(permainan.daftar_aset[id_aset].sumber):
		kirim_aset(id_pemain, permainan.daftar_aset[id_aset].sumber, permainan.daftar_aset[id_aset].nama)
@rpc("any_peer") func _hapus_objek(jalur_objek : String):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		var jalur_objek_dihapus : PackedStringArray = jalur_objek.split("/", false)
		var nama_objek_dihapus : String = jalur_objek_dihapus[jalur_objek_dihapus.size()-1]
		if pool_objek.has(nama_objek_dihapus):	pool_objek.erase(nama_objek_dihapus)
		if pool_entitas.has(nama_objek_dihapus):pool_entitas.erase(nama_objek_dihapus)
		for p in cek_visibilitas_pool_objek:
			if cek_visibilitas_pool_objek[p].has(nama_objek_dihapus):
				cek_visibilitas_pool_objek[p].erase(nama_objek_dihapus)
		for p in cek_visibilitas_pool_entitas:
			if cek_visibilitas_pool_entitas[p].has(nama_objek_dihapus):
				cek_visibilitas_pool_entitas[p].erase(nama_objek_dihapus)
		print("%s => objek [%s] dihapus" % [permainan.detikKeMenit(Time.get_ticks_msec()), nama_objek_dihapus])
		# Timeline : hapus objek
		var frame_sekarang = timeline["data"]["frame"]
		if not timeline.has(frame_sekarang): timeline[frame_sekarang] = {}
		timeline[frame_sekarang][nama_objek_dihapus] = {
			"tipe": "hapus"
		}
		_hilangkan_objek(jalur_objek)
		rpc("_hilangkan_objek", jalur_objek)
@rpc("authority") func _spawn_visibilitas_pemain(id : int, data : Dictionary):
	if permainan != null and dunia != null:
		var instance_pemain : Karakter
		match data["model"]["gender"]:
			"L": instance_pemain = permainan.karakter_cowok.instantiate();
			"P": instance_pemain = permainan.karakter_cewek.instantiate();
		if !is_instance_valid(instance_pemain): print("tidak dapat menambahkan pemain "+str(id)); return
		
		# terapkan data pemain ke model pemain
		instance_pemain.id_pemain = id
		instance_pemain.name = str(id)
		instance_pemain.nama 				= data["nama"]
		instance_pemain.gender 				= data["model"]["gender"]
		instance_pemain.model["alis"] 		= data["model"]["alis"]
		instance_pemain.model["garis_mata"] = data["model"]["garis_mata"]
		instance_pemain.model["mata"] 		= data["model"]["mata"]
		instance_pemain.warna["mata"] 		= data["model"]["warna_mata"]
		instance_pemain.model["rambut"] 	= data["model"]["rambut"]
		instance_pemain.warna["rambut"] 	= data["model"]["warna_rambut"]
		instance_pemain.model["baju"] 		= data["model"]["baju"]
		instance_pemain.warna["baju"] 		= data["model"]["warna_baju"]
		instance_pemain.model["celana"] 	= data["model"]["celana"]
		instance_pemain.warna["celana"] 	= data["model"]["warna_celana"]
		instance_pemain.model["sepatu"] 	= data["model"]["sepatu"]
		instance_pemain.warna["sepatu"] 	= data["model"]["warna_sepatu"]
		
		# tambahkan pemain ke dunia
		dunia.get_node("pemain").add_child(instance_pemain, true)
		
		# terapkan kondisi
		instance_pemain.position = data["posisi"]
		instance_pemain.rotation = data["rotasi"]
		instance_pemain.gestur = data["kondisi"]["mode_gestur"]
		instance_pemain.arah_gerakan = data["kondisi"]["arah_gerakan"]
		instance_pemain.arah_pandangan = data["kondisi"]["arah_pandangan"]
		instance_pemain.gestur_jongkok = data["kondisi"]["gestur_jongkok"]
		instance_pemain.mode_menyerang = data["kondisi"]["mode_menyerang"]
		
		# terapkan tampilan
		instance_pemain.atur_model()
		instance_pemain.atur_warna()
		
		# hindari kalkulasi yang tidak dibutuhkan
		instance_pemain.set_process(false)
		instance_pemain.set_physics_process(false)
		instance_pemain.get_node("pengamat").set_process(false)
@rpc("authority") func _spawn_visibilitas_entitas(jalur_instance_entitas, id_pemroses_entitas : int, nama_entitas : String, posisi_entitas : Vector3, rotasi_entitas : Vector3, kondisi_entitas : Array):
	if permainan != null and dunia != null:
		if dunia.get_node("entitas").get_node_or_null(nama_entitas) == null and load(jalur_instance_entitas) != null:
			var tmp_entitas : Node3D = load(jalur_instance_entitas).instantiate()
			var tmp_nama = tmp_entitas.name
			tmp_entitas.name = nama_entitas
			tmp_entitas.id_proses = id_pemroses_entitas
			for p in kondisi_entitas.size():
				if tmp_entitas.get(kondisi_entitas[p][0]) != null:	tmp_entitas.set(kondisi_entitas[p][0], kondisi_entitas[p][1])
				elif kondisi_entitas[p][0] == "id_entitas":			tmp_entitas.set_meta("id_entitas", kondisi_entitas[p][1])
				else: push_error("[Galat] "+tmp_nama+" tidak memiliki properti ["+kondisi_entitas[p][0]+"]")
			dunia.get_node("entitas").add_child(tmp_entitas, true)
			tmp_entitas.global_transform.origin = posisi_entitas
			tmp_entitas.rotation = rotasi_entitas
@rpc("authority") func _spawn_visibilitas_objek(jalur_instance_objek, id_pengubah : int, nama_objek : String, posisi_objek : Vector3, rotasi_objek : Vector3, properti_objek : Array):
	if permainan != null and dunia != null:
		if dunia.get_node("objek").get_node_or_null(nama_objek) == null and load(jalur_instance_objek) != null:
			var tmp_objek : Node3D = load(jalur_instance_objek).instantiate()
			var tmp_nama = tmp_objek.name
			tmp_objek.name = nama_objek
			dunia.get_node("objek").add_child(tmp_objek, true)
			for p in properti_objek.size():
				if tmp_objek.get(properti_objek[p][0]) != null:
					if properti_objek[p][0] == "kode":
						var compile_kode = permainan._compile_blok_kode(properti_objek[p][1])
						if compile_kode != null: tmp_objek.kode = compile_kode
					else: tmp_objek.set(properti_objek[p][0], properti_objek[p][1])
				elif properti_objek[p][0] == "id_objek":
					tmp_objek.set_meta("id_objek", properti_objek[p][1])
					#Panku.notify("Mengatur metadata ID Objek [%s] menjadi : %s" % [nama_objek, properti_objek[p][1]])
				else: push_error("[Galat] "+tmp_nama+" tidak memiliki properti ["+properti_objek[p][0]+"]")
			tmp_objek.id_pengubah = id_pengubah
			tmp_objek.global_transform.origin = posisi_objek
			tmp_objek.rotation = rotasi_objek
@rpc("authority") func _spawn_visibilitas_karakter(jalur_instance_karakter, id_pengubah : int, nama_karakter : String, posisi_karakter : Vector3, rotasi_karakter : Vector3, kondisi_karakter : Array):
	if permainan != null and dunia != null:
		if dunia.get_node("karakter").get_node_or_null(nama_karakter) == null and load(jalur_instance_karakter) != null:
			var tmp_karakter : Node3D = load(jalur_instance_karakter).instantiate()
			var tmp_nama = tmp_karakter.name
			tmp_karakter.name = nama_karakter
			dunia.get_node("karakter").add_child(tmp_karakter, true)
			for p in kondisi_karakter.size():
				if tmp_karakter.get(kondisi_karakter[p][0]) != null:
					if kondisi_karakter[p][0] == "kode":
						var compile_kode = permainan._compile_blok_kode(kondisi_karakter[p][1])
						if compile_kode != null: tmp_karakter.kode = compile_kode
					else: tmp_karakter.set(kondisi_karakter[p][0], kondisi_karakter[p][1])
				else: push_error("[Galat] "+tmp_nama+" tidak memiliki kondisi ["+kondisi_karakter[p][0]+"]")
			tmp_karakter.id_pengubah = id_pengubah
			tmp_karakter.global_transform.origin = posisi_karakter
			tmp_karakter.rotation = rotasi_karakter
@rpc("authority") func _sinkronkan_kondisi_pemain(id_pemain : int, kondisi_pemain : Array):
	if permainan != null and dunia != null:
		if dunia.get_node("pemain").get_node_or_null(str(id_pemain)) != null:
			var _pemain : Karakter = dunia.get_node("pemain").get_node(str(id_pemain))
			for kondisi in kondisi_pemain:
				if kondisi[0] == "mati":				_pemain._ragdoll = kondisi[1]
				elif kondisi[0] == "posisi":			_pemain.position = kondisi[1]
				elif kondisi[0] == "rotasi":			_pemain.rotation = kondisi[1]
				elif kondisi[0] == "melompat":			_pemain.melompat = kondisi[1]
				elif kondisi[0] == "menyerang":			_pemain.menyerang = kondisi[1]
				elif kondisi[0] == "mode_gestur":		_pemain.gestur = kondisi[1]
				elif kondisi[0] == "pose_duduk":		_pemain.pose_duduk = kondisi[1]
				elif kondisi[0] == "arah_gerakan":		_pemain.arah_gerakan = kondisi[1]
				elif kondisi[0] == "arah_pandangan":	_pemain.arah_pandangan = kondisi[1]
				elif kondisi[0] == "gestur_jongkok":	_pemain.gestur_jongkok = kondisi[1]
				elif kondisi[0] == "mode_menyerang":	_pemain.mode_menyerang = kondisi[1]
				elif kondisi[0] == "arah_terserang":	_pemain._percepatan_ragdoll = kondisi[1]
@rpc("authority") func _sinkronkan_kondisi_entitas(nama_entitas : String, kondisi_entitas : Array):
	if permainan != null and dunia != null:
		if dunia.get_node("entitas").get_node_or_null(nama_entitas) != null:
			for p in kondisi_entitas.size():
				if dunia.get_node("entitas").get_node(nama_entitas).get(kondisi_entitas[p][0]) != null:
					dunia.get_node("entitas").get_node(nama_entitas).set(kondisi_entitas[p][0], kondisi_entitas[p][1])
				# 25/04/25 :: set kondisi properti kustom
				if kondisi_entitas[p][0] == "kondisi":
					for p2 in kondisi_entitas[p][1].size():
						if dunia.get_node("entitas").get_node(nama_entitas).get(kondisi_entitas[p][1][p2][0]) != null:
							dunia.get_node("entitas").get_node(nama_entitas).set(kondisi_entitas[p][1][p2][0], kondisi_entitas[p][1][p2][1])
@rpc("authority") func _sinkronkan_kondisi_objek(nama_objek : String, kondisi_objek : Array):
	if permainan != null and dunia != null:
		if dunia.get_node("objek").get_node_or_null(nama_objek) != null:
			for p in kondisi_objek.size():
				if kondisi_objek[p][0] == "kode":
					dunia.get_node("objek").get_node(nama_objek).kode = permainan._compile_blok_kode(kondisi_objek[p][1])
				elif dunia.get_node("objek").get_node(nama_objek).get(kondisi_objek[p][0]) != null:
					dunia.get_node("objek").get_node(nama_objek).set(kondisi_objek[p][0], kondisi_objek[p][1])
@rpc("authority") func _sinkronkan_kondisi_karakter(nama_karakter : String, kondisi_karakter : Array):
	if permainan != null and dunia != null:
		if dunia.get_node("karakter").get_node_or_null(nama_karakter) != null:
			for p in kondisi_karakter.size():
				if kondisi_karakter[p][0] == "kode":
					dunia.get_node("karakter").get_node(nama_karakter).kode = permainan._compile_blok_kode(kondisi_karakter[p][1])
				elif dunia.get_node("karakter").get_node(nama_karakter).get(kondisi_karakter[p][0]) != null:
					dunia.get_node("karakter").get_node(nama_karakter).set(kondisi_karakter[p][0], kondisi_karakter[p][1])
@rpc("authority") func _hapus_visibilitas_pemain(id_pemain : int):
	if permainan != null and dunia != null:
		if dunia.get_node("pemain").get_node_or_null(str(id_pemain)) != null:
			if dunia.get_node("pemain").get_node(str(id_pemain)).has_method("hapus"):
				dunia.get_node("pemain").get_node(str(id_pemain)).hapus()
			else:
				dunia.get_node("pemain").get_node(str(id_pemain)).queue_free()
@rpc("authority") func _hapus_visibilitas_entitas(nama_entitas : String):
	if permainan != null and dunia != null:
		if dunia.get_node("entitas").get_node_or_null(nama_entitas) != null:
			if dunia.get_node("entitas").get_node(nama_entitas).has_method("hapus"):
				dunia.get_node("entitas").get_node(nama_entitas).hapus()
			else:
				dunia.get_node("entitas").get_node(nama_entitas).queue_free()
@rpc("authority") func _hapus_visibilitas_objek(nama_objek : String):
	if permainan != null and dunia != null:
		if dunia.get_node("objek").get_node_or_null(nama_objek) != null:
			if dunia.get_node("objek").get_node(nama_objek).has_method("hapus"):
				dunia.get_node("objek").get_node(nama_objek).hapus()
			else:
				dunia.get_node("objek").get_node(nama_objek).queue_free()
@rpc("authority") func _hapus_visibilitas_karakter(nama_karakter : String):
	if permainan != null and dunia != null:
		if dunia.get_node("karakter").get_node_or_null(nama_karakter) != null:
			if dunia.get_node("karakter").get_node(nama_karakter).has_method("hapus"):
				dunia.get_node("karakter").get_node(nama_karakter).hapus()
			else:
				dunia.get_node("karakter").get_node(nama_karakter).queue_free()
@rpc("authority") func _hilangkan_objek(jalur_objek : NodePath):
	var objek_dihapus = get_node_or_null(jalur_objek)
	if objek_dihapus != null:
		if objek_dihapus.has_method("hapus"):
			objek_dihapus.hapus()
		else:
			objek_dihapus.queue_free()
	#else: Panku.notify("error")
@rpc("authority") func _terima_dorongan_dari_pemain(_id_pemain : int, arah_dorongan : Vector3):
	permainan.karakter.get_node("pose").set("active", false)
	permainan.karakter.velocity += arah_dorongan
	await get_tree().create_timer(0.4).timeout
	permainan.karakter.get_node("pose").set("active", true)
