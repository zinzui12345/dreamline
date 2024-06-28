extends Node

class_name Server

@onready var permainan = get_tree().get_root().get_node("Dreamline")

var interface = null
var peer : MultiplayerPeer
var broadcast : ServerAdvertiser
var upnp : UPNP
var headless = false
var publik = false
var ip_publik
var jumlah_pemain = 32
var pemain_terhubung = 0
var map = "pulau"
var nama = "bebas"
var pemain : Dictionary
var timeline : Dictionary = {}
var mode_replay = false
var file_replay = "user://rekaman.dreamline_replay"
var mode_uji_performa = false
var jumlah_entitas = 0
var jumlah_objek = 0
var pool_entitas : Dictionary = {}
var pool_objek : Dictionary = {}
var cek_visibilitas_pool_entitas : Dictionary = {} # [id_pemain][nama_entitas] = "spawn" ? "hapus"
var cek_visibilitas_pool_objek : Dictionary = {} # [id_pemain][nama_objek] = "spawn" ? "hapus"

const jarak_render_entitas = 10 # FIXME : set ke 50

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

const POSISI_SPAWN_RANDOM := 5.0

func _process(_delta):
	if permainan != null and permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if permainan.dunia != null:
			# atur frame timeline
			if !mode_replay:
				if permainan.dunia.process_mode != PROCESS_MODE_DISABLED and timeline.has("data"):
					if timeline.size() > 700:
						var b_data_timeline = timeline["data"]
						# hasilkan nama_file
						var nama_file_timeline = "timeline_%s-%s-%s_%s.timelinepart" % [map, nama, timeline["data"]["id"], timeline["data"]["urutan"]]
						# simpan data timeline ke nama_file
						# - hapus timeline["data"], sisakan data frame
						timeline.erase("data")
						# - kalau direktori bagian belum ada, buat
						if !DirAccess.dir_exists_absolute("user://timeline_part"):
							DirAccess.make_dir_absolute("user://timeline_part")
						var file = FileAccess.open("user://timeline_part/"+nama_file_timeline, FileAccess.WRITE)
						# - jangan langsung stor, hapus dulu frame yang kosong!
						var indeks_timeline = timeline.keys()
						for frame in indeks_timeline.size(): 
							if timeline[indeks_timeline[frame]].size() < 1:
								timeline.erase(indeks_timeline[frame])
						indeks_timeline.clear()
						file.store_var(timeline)
						file.close()
						# kosongkan data frame timeline
						timeline.clear()
						timeline["data"] = b_data_timeline
						# tambah urutan
						timeline["data"]["urutan"] += 1
					else:
						timeline["data"]["frame"] = Time.get_ticks_msec() - timeline["data"]["mulai"]
			
			# tentukan visibilitas entitas dan objek pada tiap pemain
			if permainan.dunia.get_node("pemain").get_child_count() > 0:
				# loop array pemain
				for p in permainan.dunia.get_node("pemain").get_child_count():
					var b_pemain : Karakter = permainan.dunia.get_node("pemain").get_child(p)
					# loop array pool_entitas
					if !pool_entitas.is_empty():
						var indeks_pool_entitas = pool_entitas.keys()
						for i_pool_entitas in indeks_pool_entitas.size(): 
							var nama_entitas = indeks_pool_entitas[i_pool_entitas]
							# cek jarak pemain dengan entitas
							var jarak_pemain = b_pemain.global_position.distance_to(pool_entitas[nama_entitas]["posisi"])
							# pastikan keadaan visibilitas pool
							if cek_visibilitas_pool_entitas.get(b_pemain.id_pemain) == null:
								cek_visibilitas_pool_entitas[b_pemain.id_pemain] = {}
							if cek_visibilitas_pool_entitas[b_pemain.id_pemain].get(nama_entitas) == null:
								cek_visibilitas_pool_entitas[b_pemain.id_pemain][nama_entitas] = "hapus"
							# jika jarak pemain lebih dari jarak render entitas
							if jarak_pemain > jarak_render_entitas:
								# pastikan pemain saat ini tidak mengubah entitas
								if pool_entitas[nama_entitas]["id_pengubah"] != b_pemain.id_pemain:
									# cek jika id_proses telah diatur dan pemain saat ini adalah pemroses
									if pool_entitas[nama_entitas]["id_proses"] != -1 and pool_entitas[nama_entitas]["id_proses"] == b_pemain.id_pemain:
										# rpc atur -1 sebagai pemroses entitas ke semua peer
										sinkronkan_kondisi_entitas(-1, nama_entitas, [["id_proses", -1]])
										# atur id_proses dengan -1
										pool_entitas[nama_entitas]["id_proses"] = -1
									# hanya hapus jika pool telah di-spawn
									if cek_visibilitas_pool_entitas[b_pemain.id_pemain][nama_entitas] == "spawn":
										# rpc hapus pool_entitas
										hapus_pool_entitas(b_pemain.id_pemain, nama_entitas)
										# ubah visibilitas pool agar jangan rpc lagi
										cek_visibilitas_pool_entitas[b_pemain.id_pemain][nama_entitas] = "hapus"
							# jika jarak pemain kurang dari jarak render entitas
							else:
								# hanya spawn jika pool belum di-spawn
								if cek_visibilitas_pool_entitas[b_pemain.id_pemain][nama_entitas] == "hapus":
									# rpc spawn pool entitas
									spawn_pool_entitas(b_pemain.id_pemain, nama_entitas, pool_entitas[nama_entitas]["jalur_instance"], pool_entitas[nama_entitas]["id_proses"], pool_entitas[nama_entitas]["posisi"], pool_entitas[nama_entitas]["rotasi"], pool_entitas[nama_entitas]["kondisi"])
									# ubah visibilitas pool agar jangan rpc lagi
									cek_visibilitas_pool_entitas[b_pemain.id_pemain][nama_entitas] = "spawn"
								# cek jika id_proses belum diatur
								if pool_entitas[nama_entitas]["id_proses"] == -1:
									# rpc atur pemain sebagai pemroses entitas ke semua peer
									sinkronkan_kondisi_entitas(-1, nama_entitas, [["id_proses", b_pemain.id_pemain]])
									# atur id_proses dengan id_pemain
									pool_entitas[nama_entitas]["id_proses"] = b_pemain.id_pemain
					
					# loop array pool_objek
					if !pool_objek.is_empty():
						var indeks_pool_objek = pool_objek.keys()
						for i_pool_objek in indeks_pool_objek.size(): 
							var nama_objek = indeks_pool_objek[i_pool_objek]
							# cek jarak pemain dengan objek
							var jarak_pemain = b_pemain.global_position.distance_to(pool_objek[nama_objek]["posisi"])
							# pastikan keadaan visibilitas pool
							if cek_visibilitas_pool_objek.get(b_pemain.id_pemain) == null:
								cek_visibilitas_pool_objek[b_pemain.id_pemain] = {}
							if cek_visibilitas_pool_objek[b_pemain.id_pemain].get(nama_objek) == null:
								cek_visibilitas_pool_objek[b_pemain.id_pemain][nama_objek] = "hapus"
							# jika frustum culling diaktifkan dan jarak pemain lebih dari jarak render objek
							if b_pemain.get_node("PlayerInput").gunakan_frustum_culling and jarak_pemain > pool_objek[nama_objek]["jarak_render"]:
								# pastikan pemain saat ini tidak mengubah objek
								if pool_objek[nama_objek]["id_pengubah"] != b_pemain.id_pemain:
									# hanya hapus jika pool telah di-spawn
									if cek_visibilitas_pool_objek[b_pemain.id_pemain][nama_objek] == "spawn":
										# rpc hapus pool_objek
										hapus_pool_objek(b_pemain.id_pemain, nama_objek)
										# ubah visibilitas pool agar jangan rpc lagi
										cek_visibilitas_pool_objek[b_pemain.id_pemain][nama_objek] = "hapus"
							# jika jarak pemain kurang dari jarak render objek
							else:
								# hanya spawn jika pool belum di-spawn
								if cek_visibilitas_pool_objek[b_pemain.id_pemain][nama_objek] == "hapus":
									# rpc spawn pool objek
									spawn_pool_objek(b_pemain.id_pemain, nama_objek, pool_objek[nama_objek]["jalur_instance"], pool_objek[nama_objek]["id_pengubah"], pool_objek[nama_objek]["posisi"], pool_objek[nama_objek]["rotasi"], pool_objek[nama_objek]["properti"])
									# ubah visibilitas pool agar jangan rpc lagi
									cek_visibilitas_pool_objek[b_pemain.id_pemain][nama_objek] = "spawn"

func buat_koneksi():
	interface = MultiplayerAPI.create_default_interface()
	peer = ENetMultiplayerPeer.new()
	broadcast = ServerAdvertiser.new()
	peer.create_server(10567, jumlah_pemain)
	interface.connect("peer_connected", self._pemain_bergabung)
	interface.connect("peer_disconnected", self._pemain_terputus)
	interface.set_multiplayer_peer(peer)
	get_tree().set_multiplayer(interface)
	#interface.set_root_path(NodePath("/root/dunia"))
	interface.set_refuse_new_connections(false)
	client.id_koneksi = 1
	broadcast.name = "broadcast server"
	broadcast.broadcastPort = 10568
	broadcast.serverInfo["nama"] = nama
	broadcast.serverInfo["sys"] = permainan.data["sistem"]
	broadcast.serverInfo["map"] = map
	broadcast.serverInfo["jml_pemain"] = pemain_terhubung
	broadcast.serverInfo["max_pemain"] = jumlah_pemain
	permainan.add_child(broadcast)
	# setup timeline
	timeline = {
		"data": {
			"id":	 permainan.hasilkanKarakterAcak(5),
			"map":	 map,
			"mulai": Time.get_ticks_msec(),
			"frame": 0,
			"urutan":1
		}
	}
	# setup pool
	pool_entitas.clear()
	pool_objek.clear()
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
func putuskan():
	interface.set_refuse_new_connections(true)
	broadcast.queue_free()
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
	var b_data_frame = timeline
	# - kosongkan data frame timeline
	timeline.clear()
	# - pindahkan kembali timeline["data"] ke timeline
	timeline["data"] = b_data_timeline
	# - dapatkan nama_file timeline berdasarkan id_timeline
	for i in timeline["data"]["urutan"] - 1:
		var nama_file_timeline = "timeline_%s-%s-%s_%s.timelinepart" % [map, nama, timeline["data"]["id"], str(i+1)]
		# > buka nama_file_timeline lalu set ke tmp_frame
		if FileAccess.file_exists("user://timeline_part/"+nama_file_timeline): # cegah error jika seandainya file corrupt
			var file = FileAccess.open("user://timeline_part/"+nama_file_timeline, FileAccess.READ_WRITE)
			var tmp_frame = file.get_var()
			# > merge tmp_frame ke timeline
			timeline.merge(tmp_frame, true)
			# > tutup file nama_file_timeline
			file.close()
			# > hapus file nama_file_timeline
			DirAccess.remove_absolute("user://timeline_part/"+nama_file_timeline)
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
	cek_visibilitas_pool_entitas.clear()
	cek_visibilitas_pool_objek.clear()
	Panku.notify(TranslationServer.translate("%putuskanserver"))
	Panku.gd_exprenv.remove_env("server")

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
func gunakan_entitas(nama_entitas : String, fungsi : String):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		_gunakan_entitas(nama_entitas, multiplayer.get_unique_id(), fungsi)
	else:
		rpc_id(1, "_gunakan_entitas", nama_entitas, multiplayer.get_unique_id(), fungsi)
func cek_visibilitas_entitas_terhadap_pemain(id_pemain : int, jalur_objek, jarak_render_objek = 100) -> bool:
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		var ref_pemain : Karakter = permainan.dunia.get_node_or_null("pemain/"+str(id_pemain))
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
func edit_objek(nama_objek : String, fungsi : bool):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		_edit_objek(nama_objek, multiplayer.get_unique_id(), fungsi)
	else:
		rpc_id(1, "_edit_objek", nama_objek, multiplayer.get_unique_id(), fungsi)
func terapkan_percepatan_objek(jalur_objek : String, nilai_percepatan : Vector3):
	_terapkan_percepatan_objek(jalur_objek, nilai_percepatan)
	rpc("_terapkan_percepatan_objek", jalur_objek, nilai_percepatan)
func fungsikan_objek(jalur_objek : NodePath, nama_fungsi : StringName, parameter : Array = []):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		var t_objek = get_node_or_null(jalur_objek)
		if t_objek != null: rpc("_fungsikan_objek", jalur_objek, nama_fungsi, parameter)
func hapus_objek(jalur_objek):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		# TODO : hapus dari pool_entitas kalo ada!
		_hapus_objek(jalur_objek)
		rpc("_hapus_objek", jalur_objek)

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
	if permainan.dunia.get_node_or_null("posisi_spawn") != null:
		# HACK : kesalahan class akan menimbulkan softlock pada client ketika tetputus pada proses koneksi
		# [mis. permainan.dunia.map.get_node_or_null]
		# ini bisa dipake untuk testing client
		posisi = permainan.dunia.get_node("posisi_spawn").position
		rotasi = permainan.dunia.get_node("posisi_spawn").rotation
	client.rpc_id(
		id_pemain, 
		"gabung_ke_server", 
		nama, 
		map, 
		posisi,
		rotasi
	)
	print("%s => pemain [%s] telah bergabung" % [Time.get_ticks_msec(), id_pemain])
	pemain_terhubung += 1
func _pemain_terputus(id_pemain):
	# simpan kondisi terakhir berdasarkan id client kemudian hapus
	if permainan.dunia.get_node_or_null("pemain/"+str(id_pemain)) != null:
		for idx_pemain in pemain.keys():
			if pemain[idx_pemain]["id_client"] == id_pemain:
				pemain[idx_pemain]["posisi"] = permainan.dunia.get_node("pemain/"+str(id_pemain)).position
				pemain[idx_pemain]["rotasi"] = permainan.dunia.get_node("pemain/"+str(id_pemain)).rotation
		permainan.dunia.get_node("pemain/"+str(id_pemain))._hapus()
		permainan._hapus_daftar_pemain(id_pemain)
		client.rpc("hapus_pemain", id_pemain)
		# TODO : 26/06/24 :: loop pool_objek kemudian reset id_pengubah pada objek yang id_pengubah == id_pemain
		print("%s => pemain [%s] telah terputus" % [Time.get_ticks_msec(), id_pemain])
		pemain_terhubung -= 1

@rpc("any_peer") func _tambahkan_pemain_ke_dunia(id_pemain, id_koneksi, data_pemain):
	if permainan.koneksi == permainan.MODE_KONEKSI.SERVER:
		# INFO : (5b2) tambahkan pemain client ke dunia
		if pemain.has(id_koneksi):
			pemain[id_koneksi]["id_client"] = id_pemain
			data_pemain["posisi"] = pemain[id_koneksi]["posisi"]
			data_pemain["rotasi"] = pemain[id_koneksi]["rotasi"]
		else:
			pemain[id_koneksi] = {
				"id_client": id_pemain,
				"posisi": data_pemain["posisi"],
				"rotasi": data_pemain["rotasi"]
			}
		permainan._tambahkan_pemain(id_pemain, data_pemain)
		print("%s => tambah pemain [%s] ke dunia" % [Time.get_ticks_msec(), id_pemain])
@rpc("any_peer") func _terima_suara_pemain(id_pemain : int, data_suara : PackedByteArray, ukuran_buffer : int):
	print("pemain [%s] berbicara (%s)" % [str(id_pemain), str(ukuran_buffer)])
	# dekompresi dan simpan data suara ke array yang kemudian dimainkan pada thread
	var tmp_data_suara : PackedByteArray = data_suara.decompress(ukuran_buffer, FileAccess.COMPRESSION_ZSTD)
	permainan.dunia.get_node("pemain/"+str(id_pemain)+"/suara").array_suara.append(tmp_data_suara)
	# mainkan suara *
	permainan.dunia.get_node("pemain/"+str(id_pemain)+"/suara").bicara()
@rpc("any_peer") func _terima_pesan_pemain(id_pemain : int, pesan : String):
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
		permainan.dunia.get_node("pemain/"+str(id_pemain)).nama,
		pesan
	]
	#print_debug(teks)
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: rpc("_terima_pesan_pemain", id_pemain, pesan)
	permainan._tampilkan_pesan(teks)
@rpc("any_peer") func _tambahkan_entitas(jalur_skena : String, posisi : Vector3, rotasi : Vector3, properti : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if load(jalur_skena) != null:
			jumlah_entitas += 1
			var nama_entitas = "entitas_"+str(jumlah_entitas)
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
			if not server.mode_replay:
				if not server.timeline.has(server.timeline["data"]["frame"]):
					server.timeline[server.timeline["data"]["frame"]] = {}
				server.timeline[server.timeline["data"]["frame"]][nama_entitas] = {
					"tipe": 		"spawn",
					"tipe_objek":	"entitas",
					"sumber": 		jalur_skena,
					"posisi":		posisi,
					"rotasi":		rotasi,
					"properti":		properti,
				}
		else: print("[Galat] entitas %s tidak ditemukan" % [jalur_skena]); Panku.notify("404 : Objek tak ditemukan [%s]" % [jalur_skena])
	else: print("[Galat] fungsi [tambahkan_entitas] hanya dapat dipanggil pada server"); Panku.notify("403 : Terlarang")
@rpc("any_peer") func _tambahkan_objek(jalur_skena : String, posisi : Vector3, rotasi : Vector3, jarak_render : int, properti : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if load(jalur_skena) != null:
			jumlah_objek += 1
			var nama_objek = "objek_"+str(jumlah_objek)
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
			if not server.mode_replay:
				if not server.timeline.has(server.timeline["data"]["frame"]):
					server.timeline[server.timeline["data"]["frame"]] = {}
				server.timeline[server.timeline["data"]["frame"]][nama_objek] = {
					"tipe": 		"spawn",
					"tipe_objek":	"objek",
					"sumber": 		jalur_skena,
					"posisi":		posisi,
					"rotasi":		rotasi,
					"properti":		properti,
				}
		else: print("[Galat] objek %s tidak ditemukan" % [jalur_skena]); Panku.notify("404 : Objek tak ditemukan [%s]" % [jalur_skena])
	else: print("[Galat] fungsi [tambahkan_objek] hanya dapat dipanggil pada server"); Panku.notify("403 : Terlarang")
@rpc("any_peer") func _gunakan_entitas(nama_entitas : String, id_pengguna : int, fungsi : String):
	var t_entitas = permainan.dunia.get_node_or_null("entitas/" + nama_entitas)
	if t_entitas != null and t_entitas.has_method(fungsi):
		t_entitas.call(fungsi, id_pengguna)
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and pool_entitas.get(nama_entitas) != null:
		rpc("_gunakan_entitas", nama_entitas, id_pengguna, fungsi)
@rpc("any_peer") func _sesuaikan_posisi_entitas(nama_entitas : String, id_pemain : int):
	# kirim posisi entitas ke client kalau posisi di client de-sync
	var t_entitas = permainan.dunia.get_node_or_null("entitas/" + nama_entitas)
	if t_entitas != null:
		client.rpc_id(id_pemain, "dapatkan_posisi_entitas", nama_entitas, t_entitas.global_transform.origin, t_entitas.rotation_degrees)
	else:
		client.rpc_id(id_pemain, "dapatkan_posisi_entitas", nama_entitas, entitas[nama_entitas]["posisi"], entitas[nama_entitas]["rotasi"])
@rpc("any_peer") func _sesuaikan_kondisi_entitas(id_pengatur : int, nama_entitas : String, kondisi_entitas : Array):
	if permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and pool_entitas[nama_entitas]["id_proses"] == id_pengatur:
		for p in kondisi_entitas.size():
			if kondisi_entitas[p][0] == "position":		pool_entitas[nama_entitas]["posisi"] = kondisi_entitas[p][1]
			elif kondisi_entitas[p][0] == "rotation":	pool_entitas[nama_entitas]["rotasi"] = kondisi_entitas[p][1]
			elif pool_entitas[nama_entitas].get(kondisi_entitas[p][0]) != null:
				pool_entitas[nama_entitas][kondisi_entitas[p][0]] = kondisi_entitas[p][1]
			else:
				for k in pool_entitas[nama_entitas]["kondisi"].size():
					if pool_entitas[nama_entitas]["kondisi"][k][0] == kondisi_entitas[p][0]:
						pool_entitas[nama_entitas]["kondisi"][k][1] = kondisi_entitas[p][1]
		# Timeline : sinkronkan entitas (rekam)
		if not server.mode_replay:
			if not server.timeline.has(server.timeline["data"]["frame"]):
				server.timeline[server.timeline["data"]["frame"]] = {}
			server.timeline[server.timeline["data"]["frame"]][nama_entitas] = {
				"tipe": 		"sinkron",
				"posisi":		pool_entitas[nama_entitas]["posisi"],
				"rotasi":		pool_entitas[nama_entitas]["rotasi"],
				"properti":		pool_entitas[nama_entitas]["kondisi"],
			}
		# kirim ke semua peer yang di-spawn kecuali id_pengatur!
		for p in permainan.dunia.get_node("pemain").get_child_count():
			if permainan.dunia.get_node("pemain").get_child(p).id_pemain != id_pengatur:
				if cek_visibilitas_pool_entitas[permainan.dunia.get_node("pemain").get_child(p).id_pemain][nama_entitas] == "spawn":
					sinkronkan_kondisi_entitas(permainan.dunia.get_node("pemain").get_child(p).id_pemain, nama_entitas, kondisi_entitas)
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
		if not server.mode_replay:
			if not server.timeline.has(server.timeline["data"]["frame"]):
				server.timeline[server.timeline["data"]["frame"]] = {}
			server.timeline[server.timeline["data"]["frame"]][nama_objek] = {
				"tipe": 		"sinkron",
				"posisi":		pool_objek[nama_objek]["posisi"],
				"rotasi":		pool_objek[nama_objek]["rotasi"],
				"properti":		pool_objek[nama_objek]["properti"],
			}
		# kirim ke semua peer yang di-spawn kecuali id_pengatur!
		for p in permainan.dunia.get_node("pemain").get_child_count():
			if permainan.dunia.get_node("pemain").get_child(p).id_pemain != id_pengatur:
				if cek_visibilitas_pool_objek[permainan.dunia.get_node("pemain").get_child(p).id_pemain][nama_objek] == "spawn":
					sinkronkan_kondisi_objek(permainan.dunia.get_node("pemain").get_child(p).id_pemain, nama_objek, properti_objek)
@rpc("authority") func _spawn_visibilitas_entitas(jalur_instance_entitas, id_pemroses_entitas : int, nama_entitas : String, posisi_entitas : Vector3, rotasi_entitas : Vector3, kondisi_entitas : Array):
	if permainan != null and permainan.dunia != null:
		if permainan.dunia.get_node("entitas").get_node_or_null(nama_entitas) == null and load(jalur_instance_entitas) != null:
			var tmp_entitas : Node3D = load(jalur_instance_entitas).instantiate()
			var tmp_nama = tmp_entitas.name
			tmp_entitas.name = nama_entitas
			tmp_entitas.id_proses = id_pemroses_entitas
			for p in kondisi_entitas.size():
				if tmp_entitas.get(kondisi_entitas[p][0]) != null: tmp_entitas.set(kondisi_entitas[p][0], kondisi_entitas[p][1])
				else: print("[Galat] "+tmp_nama+" tidak memiliki properti ["+kondisi_entitas[p][0]+"]")
			permainan.dunia.get_node("entitas").add_child(tmp_entitas, true)
			tmp_entitas.global_transform.origin = posisi_entitas
			tmp_entitas.rotation = rotasi_entitas
@rpc("authority") func _spawn_visibilitas_objek(jalur_instance_objek, id_pengubah : int, nama_objek : String, posisi_objek : Vector3, rotasi_objek : Vector3, properti_objek : Array):
	if permainan != null and permainan.dunia != null:
		if permainan.dunia.get_node("objek").get_node_or_null(nama_objek) == null and load(jalur_instance_objek) != null:
			var tmp_objek : Node3D = load(jalur_instance_objek).instantiate()
			var tmp_nama = tmp_objek.name
			tmp_objek.name = nama_objek
			permainan.dunia.get_node("objek").add_child(tmp_objek, true)
			for p in properti_objek.size():
				if tmp_objek.get(properti_objek[p][0]) != null: tmp_objek.set(properti_objek[p][0], properti_objek[p][1])
				else: print("[Galat] "+tmp_nama+" tidak memiliki properti ["+properti_objek[p][0]+"]")
			tmp_objek.id_pengubah = id_pengubah
			tmp_objek.global_transform.origin = posisi_objek
			tmp_objek.rotation = rotasi_objek
@rpc("authority") func _sinkronkan_kondisi_entitas(nama_entitas : String, kondisi_entitas : Array):
	if permainan != null and permainan.dunia != null:
		if permainan.dunia.get_node("entitas").get_node_or_null(nama_entitas) != null:
			for p in kondisi_entitas.size():
				if permainan.dunia.get_node("entitas").get_node(nama_entitas).get(kondisi_entitas[p][0]) != null:
					permainan.dunia.get_node("entitas").get_node(nama_entitas).set(kondisi_entitas[p][0], kondisi_entitas[p][1])
@rpc("authority") func _sinkronkan_kondisi_objek(nama_objek : String, kondisi_objek : Array):
	if permainan != null and permainan.dunia != null:
		if permainan.dunia.get_node("objek").get_node_or_null(nama_objek) != null:
			for p in kondisi_objek.size():
				if permainan.dunia.get_node("objek").get_node(nama_objek).get(kondisi_objek[p][0]) != null:
					permainan.dunia.get_node("objek").get_node(nama_objek).set(kondisi_objek[p][0], kondisi_objek[p][1])
@rpc("authority") func _hapus_visibilitas_entitas(nama_entitas : String):
	if permainan != null and permainan.dunia != null:
		if permainan.dunia.get_node("entitas").get_node_or_null(nama_entitas) != null:
			if permainan.dunia.get_node("entitas").get_node(nama_entitas).has_method("hapus"):
				permainan.dunia.get_node("entitas").get_node(nama_entitas).hapus()
			else:
				permainan.dunia.get_node("entitas").get_node(nama_entitas).queue_free()
@rpc("authority") func _hapus_visibilitas_objek(nama_objek : String):
	if permainan != null and permainan.dunia != null:
		if permainan.dunia.get_node("objek").get_node_or_null(nama_objek) != null:
			if permainan.dunia.get_node("objek").get_node(nama_objek).has_method("hapus"):
				permainan.dunia.get_node("objek").get_node(nama_objek).hapus()
			else:
				permainan.dunia.get_node("objek").get_node(nama_objek).queue_free()
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
@rpc("authority") func _fungsikan_objek(jalur_objek : NodePath, nama_fungsi : StringName, parameter : Array):
	var objek_difungsikan = get_node_or_null(jalur_objek)
	if objek_difungsikan != null:
		var panggil_fungsi = Callable(objek_difungsikan, nama_fungsi)
		for nilai_parameter in parameter.size():
			panggil_fungsi = panggil_fungsi.bind(
				parameter[
					(parameter.size() - 1) - nilai_parameter
				]
			)
		panggil_fungsi.call()
@rpc("authority") func _hapus_objek(jalur_objek : NodePath):
	var objek_dihapus = get_node_or_null(jalur_objek)
	if objek_dihapus != null:
		objek_dihapus.queue_free()
	#else: Panku.notify("error")
