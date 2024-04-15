# 14/04/24
extends Node3D
class_name entitas

var id_proses = -1			# id peer/pemain yang memproses entitas ini
var cek_kondisi = {}		# simpan beberapa properti di tiap frame untuk membandingkan perubahan
#const sinkron_kondisi = []	# array berisi properti kustom yang akan di-sinkronkan ke server | format sama dengan kondisi pada server (Array[ Array[nama_properti, nilai] ])
#const jalur_instance = ""	# jalur aset skena node entitas ini misalnya: "res://skena/entitas/bola_batu.scn"

func _ready(): call_deferred("_setup")
func _setup():
	if !is_instance_valid(server.permainan): return
	if get_parent().get_path() != server.permainan.dunia.get_node("entitas").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and not server.mode_replay:
			server._tambahkan_entitas(
				get("jalur_instance"),
				global_transform.origin,
				rotation,
				get("sinkron_kondisi").duplicate(true)
			)
		queue_free()
	else:
		mulai()

@onready var posisi_awal = global_transform.origin
@onready var rotasi_awal = rotation

# fungsi yang akan dipanggil pada saat node memasuki SceneTree menggantikan _ready()
func mulai():
	pass
# fungsi yang akan dipanggil setiap saat menggantikan _process(delta)
func proses(_waktu_delta : float):
	pass
# fungsi untuk menghapus entitas, menghilangkan dari dunia dan server
func hilangkan():
	# hapus dari dictionary entitas pada server
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		server.entitas.erase(name)
	# hapus instance
	queue_free()

func _process(delta):
	# hentikan proses jika node tidak berada dalam permainan
	if !is_instance_valid(server.permainan): set_process(false); return
	
	# sinkronkan perubahan kondisi
	if id_proses == client.id_koneksi:
		# reset posisi jika entitas jatuh ke void
		if global_position.y < server.permainan.batas_bawah:
			global_transform.origin = posisi_awal
			rotation		 		= rotasi_awal
		
		# buat variabel pembanding
		var perubahan_kondisi = []
		var sinkron_kondisi : Array = get("sinkron_kondisi")
		
		# cek apakah kondisi sebelumnya telah tersimpan
		if cek_kondisi.get("posisi") == null:	cek_kondisi["posisi"] = Vector3.ZERO
		if cek_kondisi.get("rotasi") == null:	cek_kondisi["rotasi"] = rotation
		
		# cek apakah kondisi berubah
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
				server._sesuaikan_kondisi_entitas(1, name, perubahan_kondisi)
			else:
				server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, perubahan_kondisi)
		
		# simpan perubahan kondisi untuk di-cek lagi
		cek_kondisi["posisi"] = position
		cek_kondisi["rotasi"] = rotation
		
		# simpan perubahan kondisi properti kustom untuk di-cek lagi
		for p in sinkron_kondisi.size():
			cek_kondisi[sinkron_kondisi[p][0]] = get(sinkron_kondisi[p][0])
	
	# panggil fungsi pemroses node
	proses(delta)
