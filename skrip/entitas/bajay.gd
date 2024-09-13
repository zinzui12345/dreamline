extends entitas

const radius_tabrak : int = 10
const sinkron_kondisi = [
	["warna_1", Color("FFF")],
	["warna_2", Color("3900ff")],
	["warna_3", Color("ff0021")],
	["warna_4", Color("ff5318")],
	["warna_5", Color("000000")],
	["id_pengemudi", -1]
]
const jalur_instance = "res://skena/entitas/bajay.tscn"
const batas_putaran_stir = 0.5

var id_pengemudi = -1:
	set(id):
		if id != -1:
			server.permainan.dunia.get_node("pemain/"+str(id)).set("gestur", "duduk")
			server.permainan.dunia.get_node("pemain/"+str(id)).set("pose_duduk", "mengemudi")
			
			# otomatis set ketika pos_tangan tidak valid kemudian ready(), skrip pada pos_tangan
			if server.permainan.dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kanan") != null:
				server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").set_target_node($setir/rotasi_stir/pos_tangan_kanan.get_path())
				server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").start()
			if server.permainan.dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kiri") != null:
				server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").set_target_node($setir/rotasi_stir/pos_tangan_kiri.get_path())
				server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").start()
			#call("add_collision_exception_with", server.permainan.dunia.get_node("pemain/"+str(id)))
		else:
			if server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengemudi)) != null:
				server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set("gestur", "berdiri")
				
				server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").set_target_node("")
				server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").stop()
				server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").set_target_node("")
				server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").stop()
		id_pengemudi = id
var arah_kemudi : Vector2
var arah_belok : float
var kecepatan_normal = 80
var kecepatan_maksimal = 150
var kecepatan_mundur = 60
var kekuatan_mesin = kecepatan_normal
var kekuatan_rem = 3
var kecepatan_laju = 0

var mat1 : StandardMaterial3D
var mat2 : StandardMaterial3D
var mat3 : StandardMaterial3D
var mat4 : StandardMaterial3D
var mat5 : StandardMaterial3D

var warna_1 : Color :
	set(ubah_warna):
		if mat1 != null: mat1.albedo_color = ubah_warna
		warna_1 = ubah_warna
var warna_2 : Color :
	set(ubah_warna):
		if mat2 != null: mat2.albedo_color = ubah_warna
		warna_2 = ubah_warna
var warna_3 : Color :
	set(ubah_warna):
		if mat3 != null: mat3.albedo_color = ubah_warna
		warna_3 = ubah_warna
var warna_4 : Color :
	set(ubah_warna):
		if mat4 != null: mat4.albedo_color = ubah_warna
		warna_4 = ubah_warna
var warna_5 : Color :
	set(ubah_warna):
		if mat5 != null: mat5.albedo_color = ubah_warna
		warna_5 = ubah_warna

# fungsi yang akan dipanggil pada saat node memasuki SceneTree menggantikan _ready()
func mulai() -> void:
	mat1 = $model/detail/bodi.get_surface_override_material(0).duplicate()
	mat2 = $model/detail/bodi.get_surface_override_material(1).duplicate()
	mat3 = $model/detail/bodi.get_surface_override_material(10).duplicate()
	mat4 = $model/detail/bodi.get_surface_override_material(5).duplicate()
	mat5 = $model/detail/bodi.get_surface_override_material(11).duplicate()
	warna_1 = warna_1
	warna_2 = warna_2
	warna_3 = warna_3
	warna_4 = warna_4
	warna_5 = warna_5
	$model/detail/bodi.set_surface_override_material(0, mat1)
	$model/detail/bodi.set_surface_override_material(1, mat2)
	$model/detail/bodi.set_surface_override_material(10, mat3)
	$model/detail/bodi.set_surface_override_material(5, mat4)
	$model/detail/bodi.set_surface_override_material(11, mat5)
	$model/detail/subreker_depan.set_surface_override_material(0, mat5)
# fungsi yang akan dipanggil setiap saat menggantikan _process(delta)
func proses(waktu_delta : float) -> void:
	if id_pengemudi == multiplayer.get_unique_id():
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).global_position = global_position
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).rotation = rotation
		
		if arah_kemudi.y > 0:	set("engine_force", kekuatan_mesin * arah_kemudi.y)
		elif arah_kemudi.y < 0:	set("engine_force", kecepatan_mundur * arah_kemudi.y)
		else:					set("engine_force", arah_kemudi.y)
		
		kecepatan_laju = self.linear_velocity * transform.basis
		
		if arah_kemudi.x != 0:
			arah_belok = arah_kemudi.x * batas_putaran_stir
		else:
			arah_belok = 0
		
		self.steering = move_toward(self.steering, arah_belok, 1.5 * waktu_delta)
		$setir/rotasi_stir.rotation_degrees.y = self.steering * 110
func _input(_event): # lepas walaupun tidak di-fokus
	if id_pengemudi == multiplayer.get_unique_id() and server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).kontrol:
		if Input.is_action_just_pressed("aksi1"):		Panku.notify("bip!")
		if Input.is_action_just_pressed("aksi2"):		await get_tree().create_timer(0.1).timeout; server.gunakan_entitas(name, "_lepas")
		
		if Input.is_action_pressed("maju"): 	arah_kemudi.y = Input.get_action_strength("maju")
		elif Input.is_action_pressed("mundur"):	arah_kemudi.y = -Input.get_action_strength("mundur")
		else:									arah_kemudi.y = 0
		
		if Input.is_action_pressed("kiri"):		arah_kemudi.x = Input.get_action_strength("kiri")
		elif Input.is_action_pressed("kanan"):	arah_kemudi.x = -Input.get_action_strength("kanan")
		else:									arah_kemudi.x = 0
		
		if Input.is_action_pressed("lompat"):	self.brake = Input.get_action_strength("lompat")
		else:									self.brake = 0

func fokus():
	server.permainan.set("tombol_aksi_2", "angkat_sesuatu")
func gunakan(id_pemain):
	if id_pengemudi == id_pemain:					server.gunakan_entitas(name, "_lepas")
	elif id_pengemudi == -1: 						server.gunakan_entitas(name, "_kemudikan")
func hapus(): # ketika tampilan dihapus
	if id_pengemudi != -1 and server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengemudi)) != null:
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").set_target_node("")
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").stop()
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").set_target_node("")
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").stop()
	queue_free()

func _kemudikan(id):
	if id == client.id_koneksi:
		server.permainan.dunia.get_node("pemain/"+str(id))._atur_penarget(false)
		await get_tree().create_timer(0.05).timeout		# ini untuk mencegah fungsi !_target di _process()
		server.permainan.set("tombol_aksi_1", "lempar_sesuatu")
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = true
		server.permainan.get_node("hud/bantuan_input/aksi1").visible = true
		server.permainan.set("tombol_aksi_2", "jatuhkan_sesuatu")
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
		server.permainan.get_node("hud/bantuan_input/aksi2").visible = true
		
		# ubah pemroses pada server
		var tmp_kondisi = [["id_proses", id], ["id_pengemudi", id]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	# atur id_pengemudi dan id_proses
	id_pengemudi = id
	id_proses = id
func _lepas(id):
	#if server.permainan.dunia.get_node("pemain").get_node_or_null(str(id)) != null:
		#call("remove_collision_exception_with", server.permainan.dunia.get_node("pemain/"+str(id)))
	#call("apply_central_force", Vector3(0, 25, 50).rotated(Vector3.UP, rotation.y))
	if id == client.id_koneksi:
		server.permainan.dunia.get_node("pemain/"+str(id))._atur_penarget(true)
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		server.permainan.get_node("hud/bantuan_input/aksi1").visible = false
		server.permainan.get_node("hud/bantuan_input/aksi2").visible = false
		
		# reset pemroses pada server
		var tmp_kondisi = [["id_proses", -1], ["id_pengemudi", -1]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	# atur ulang id_pengemudi dan id_proses
	id_pengemudi = -1
	id_proses = -1
