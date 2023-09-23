extends Node

class_name Server

@onready var permainan = get_tree().get_root().get_node("Dreamline")

var interface = null
var peer : MultiplayerPeer
var broadcast : ServerAdvertiser
var headless = false
var jumlah_pemain = 32
var pemain_terhubung = 0
var map = "showcase"
var pemain : Dictionary
var timeline : Dictionary = {
	"data": {
		"mulai": -1,
		"frame": 0
	}
}

# .: Timeline :.
# frame : Int
# timeline[frame] : Dictionary
# timeline[frame][id_entity] = { tipe: string, tipe_entitas: string, sumber: string, data: { posisi, rotasi, skala, kondisi } }
# frame adalah nilai Time.get_ticks_msec() dikurangi waktu pada saat dunia di spawn
# timeline["data"]["mulai"] adalah Time.get_ticks_msec() pada saat dunia di spawn
# timeline["data"]["frame"] adalah Time.get_ticks_msec() dikurangi timeline[0]["mulai"]
# :: penggunaan ::
# timeline[12][1] = { "spawn", "pintu", "res://model/pintu/pintuffburik.scn", "data": { Vec3(12, 1, 10), Vec3(0, 122, 0), Vec3(1, 1, 1), { "arah_gerak": Vec3(0.33, 0, 1.5) } } }
# timeline[12][1] = { "sinkron", "posisi": Vec3(12, 1, 10), "rotasi": Vec3(0, 122, 0), "skala": Vec3(1, 1, 1), "kondisi": { "arah_gerak": Vec3(0.33, 0, 1.5) } }
# timeline[12][1] = { "hapus" }

const POSISI_SPAWN_RANDOM := 5.0

func _process(_delta):
	if permainan != null:
		if permainan.dunia != null and permainan.dunia.process_mode != PROCESS_MODE_DISABLED:
			timeline["data"]["frame"] = Time.get_ticks_msec() - timeline["data"]["mulai"]

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
	broadcast.serverInfo["nama"] = "server"
	broadcast.serverInfo["sys"] = permainan.data["sistem"]
	broadcast.serverInfo["map"] = map
	broadcast.serverInfo["jml_pemain"] = pemain_terhubung
	broadcast.serverInfo["max_pemain"] = jumlah_pemain
	permainan.add_child(broadcast)
	# setup timeline
	timeline["data"]["mulai"] = Time.get_ticks_msec()
	set_process(true)
	#Panku.notify("%buatkoneksi" % [map, "localhost"]) # FIXME : unsupported format character
	Panku.gd_exprenv.register_env("server", self)
func putuskan():
	interface.set_refuse_new_connections(true)
	broadcast.queue_free()
	peer.close()
	peer = null
	interface.clear()
	interface.set_root_path(NodePath("/root"))
	interface = null
	client.id_koneksi = -44
	pemain_terhubung = 0
	# setup timeline
	set_process(false)
	timeline["data"]["frame"] = 0
	Panku.notify("%putuskanserver")
	Panku.gd_exprenv.remove_env("server")

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
	if permainan.dunia.get_node_or_null("posisi_spawn") != null: # HACK : kesalahan class akan menimbulkan softlock pada client ketika tetputus pada proses koneksi
		posisi = permainan.dunia.get_node("posisi_spawn").position
		rotasi = permainan.dunia.get_node("posisi_spawn").rotation
	client.rpc_id(
		id_pemain, 
		"gabung_ke_server", 
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
	permainan._tambah_daftar_pemain(id_pemain, data_pemain)
@rpc("any_peer") func _terima_suara_pemain(id_pemain : int, data_suara : PackedByteArray, ukuran_buffer : int):
	print("pemain [%s] berbicara (%s)" % [str(id_pemain), str(ukuran_buffer)])
	# dekompresi dan simpan data suara ke array yang kemudian dimainkan pada thread
	var tmp_data_suara : PackedByteArray = data_suara.decompress(ukuran_buffer, FileAccess.COMPRESSION_ZSTD)
	permainan.dunia.get_node("pemain/"+str(id_pemain)+"/suara").array_suara.append(tmp_data_suara)
	# mainkan suara *
	permainan.dunia.get_node("pemain/"+str(id_pemain)+"/suara").bicara()
