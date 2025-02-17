# 14/04/24
extends CollisionObject3D
class_name entitas

var id_proses : int = -1:					# id peer/pemain yang memproses entitas ini
	set(id):
		atur_pemroses(id)
		id_proses = id
var posisi_awal : Vector3
var rotasi_awal : Vector3
var cek_kondisi : Dictionary = {}			# simpan beberapa properti di tiap frame untuk membandingkan perubahan
#var efek_cahaya : GlowBorderEffectObject	# node efek garis cahaya ketika entitas di-fokus / highlight
#const sinkron_kondisi = []					# array berisi properti kustom yang akan di-sinkronkan ke server | format sama dengan kondisi pada server (Array[ Array[nama_properti, nilai] ])
#const jalur_instance = ""					# jalur aset skena node entitas ini misalnya: "res://skena/entitas/bola_batu.scn"
#const abaikan_occlusion_culling = true		# hanya tambahkan jika tidak ingin entitas menghalangi objek pada occlusion culling

func _ready() -> void:
	if process_mode == PROCESS_MODE_DISABLED and get_parent().process_mode == PROCESS_MODE_DISABLED: return
	else: call_deferred("_setup")
func _setup() -> void:
	if get_parent().get_path() != dunia.get_node("entitas").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and not server.mode_replay:
			server._tambahkan_entitas(
				get("jalur_instance"),
				global_transform.origin,
				rotation,
				get("sinkron_kondisi").duplicate(true)
			)
		queue_free()
	else:
		if get("abaikan_occlusion_culling") != null and get("abaikan_occlusion_culling") == true:
			dunia.raycast_occlusion_culling.add_exception(self)
		posisi_awal = global_position
		rotasi_awal = global_rotation
		mulai()

# fungsi yang akan dipanggil pada saat node memasuki SceneTree menggantikan _ready()
func mulai() -> void:
	pass
# fungsi yang akan dipanggil setiap saat menggantikan _process(delta)
func proses(_waktu_delta : float) -> void:
	pass
# fungsi yang akan dipanggil ketika id_proses diubah
func atur_pemroses(_id_pemroses : int) -> void:
	pass
# fungsi untuk menghapus entitas, menghilangkan dari dunia
func hapus() -> void:
	queue_free()

func _process(delta : float) -> void:
	# hentikan proses jika node tidak berada dalam permainan
	if !is_instance_valid(server.permainan): set_process(false); return
	
	# sinkronkan perubahan kondisi
	if id_proses == client.id_koneksi:
		# buat variabel pembanding
		var perubahan_kondisi = []
		var sinkron_kondisi : Array = get("sinkron_kondisi")
		
		# cek apakah kondisi sebelumnya telah tersimpan
		if cek_kondisi.get("posisi") == null:	cek_kondisi["posisi"] = Vector3.ZERO
		if cek_kondisi.get("rotasi") == null:	cek_kondisi["rotasi"] = rotation
		
		# cek apakah kondisi berubah
		if global_position.y < server.permainan.batas_bawah:
			# reset kondisi jika entitas jatuh ke void
			perubahan_kondisi.append(["position", posisi_awal])
			perubahan_kondisi.append(["rotation", rotasi_awal])
			global_transform.origin = posisi_awal
			rotation		 		= rotasi_awal
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
