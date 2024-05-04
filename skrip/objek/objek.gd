# 28/04/24
extends Node3D
class_name objek

var id_pengubah = -1:		# id peer/pemain yang mengubah objek ini
	set(id):
		if id == client.id_koneksi:
			set_process(true)
		else:
			set_process(false)
		id_pengubah = id
var cek_properti = {}		# simpan beberapa properti di tiap frame untuk membandingkan perubahan
#const properti = []		# array berisi properti kustom yang akan di-sinkronkan ke server | format sama dengan kondisi pada server (Array[ Array[nama_properti, nilai] ])
#const jalur_instance = ""	# jalur aset skena node objek ini misalnya: "res://skena/objek/tembok.scn"
var jarak_render = 10		# jarak maks render

func _ready(): call_deferred("_setup")
func _setup():
	if !is_instance_valid(server.permainan): return
	if get_parent().get_path() != server.permainan.dunia.get_node("objek").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and not server.mode_replay:
			server._tambahkan_objek(
				get("jalur_instance"),
				global_transform.origin,
				rotation,
				jarak_render,
				get("properti").duplicate(true)
			)
		queue_free()
	else:
		mulai()

# fungsi yang akan dipanggil pada saat node memasuki SceneTree menggantikan _ready()
func mulai():
	pass
# fungsi untuk menghapus objek, menghilangkan dari dunia dan server
func hilangkan():
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		# hapus dari dictionary pool_objek pada server
		server.pool_objek.erase(name)
		# Timeline : hapus objek
		var frame_sekarang = server.timeline["data"]["frame"]
		if not server.timeline.has(frame_sekarang): server.timeline[frame_sekarang] = {}
		server.timeline[frame_sekarang][name] = {
			"tipe": "hapus"
		}
	# hapus instance
	queue_free()

func _process(delta):
	# hentikan proses jika node tidak berada dalam permainan
	if !is_instance_valid(server.permainan): set_process(false); return
	
	# sinkronkan perubahan kondisi
	if id_pengubah == client.id_koneksi:
		# buat variabel pembanding
		var perubahan_kondisi = []
		var sinkron_kondisi : Array = get("properti")
		
		# cek apakah kondisi sebelumnya telah tersimpan
		if cek_properti.get("posisi") == null:	cek_properti["posisi"] = Vector3.ZERO
		if cek_properti.get("rotasi") == null:	cek_properti["rotasi"] = rotation
		if cek_properti.get("jarak_render") == null:	cek_properti["jarak_render"] = jarak_render
		
		# cek apakah kondisi berubah
		if cek_properti["posisi"] != position:	perubahan_kondisi.append(["position", position])
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
