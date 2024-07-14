# 28/04/24
extends Node3D
class_name objek

var id_pengubah : int = -1:				# id peer/pemain yang mengubah objek ini
	set(id):
		if id == client.id_koneksi:
			set_process(true)
		else:
			set_process(false)
		id_pengubah = id
var cek_properti : Dictionary = {}		# simpan beberapa properti di tiap frame untuk membandingkan perubahan
#const properti = []					# array berisi properti kustom yang akan di-sinkronkan ke server | format sama dengan kondisi pada server (Array[ Array[nama_properti, nilai] ]) | properti harus di @export!
#const jalur_instance = ""				# jalur aset skena node objek ini misalnya: "res://skena/objek/tembok.scn"

@export var wilayah_render : AABB :
	# FIXME : gak work kalo objek terputar
	set(aabb):
		if is_inside_tree():
			# TODO : reset otomatis ketika rotasi diubah
			var tmp_aabb : Array = []
			for titik in 8:
				# terapkan posisi titik AABB ke array
				tmp_aabb.append(aabb.get_endpoint(titik))
			titik_sudut = tmp_aabb
		wilayah_render = aabb
@export var jarak_render : int = 10		# jarak maks render
@export var titik_sudut : Array = []	# titik tiap sudut AABB untuk occlusion culling
@export var cek_titik : int = 0			# simpan titik terakhir occlusion culling
@export var tak_terlihat : bool = false	# simpan kondisi frustum culling
@export var terhalang : bool = false	# simpan kondisi occlusion culling

func _ready() -> void: call_deferred("_setup")
func _setup() -> void:
	if !is_instance_valid(server.permainan): return
	if get_parent().get_path() != server.permainan.dunia.get_node("objek").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and (not server.mode_replay or server.mode_uji_performa):
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
func mulai() -> void:
	pass
# fungsi untuk memindahkan posisi lokal objek berdasarkan jarak
func pindahkan(arah : Vector3) -> void:
	if id_pengubah < 1:
		if client.id_koneksi == 1:
			server._edit_objek(name, 1, true, false)
		else:
			server.rpc_id(1, "_edit_objek", name, client.id_koneksi, true, false)
		var posisi_perpindahan : Vector3 = global_transform.origin + arah
		# FIXME : cek apakah privilage edit telah didapatkan
		await get_tree().create_timer(0.05).timeout
		cek_properti["posisi"] = posisi_perpindahan
		set_indexed("global_transform:origin", posisi_perpindahan)
		if client.id_koneksi == 1:
			server._sesuaikan_properti_objek(1, name, [["position", cek_properti["posisi"]]])
			server._edit_objek(name, 1, false, false)
		else:
			server.rpc_id(1, "_sesuaikan_properti_objek", client.id_koneksi, name, [["position", cek_properti["posisi"]]])
			server.rpc_id(1, "_edit_objek", name, client.id_koneksi, false, false)
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
