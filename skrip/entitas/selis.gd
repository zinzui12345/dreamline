# 29/09/23
extends entitas

const jalur_instance = "res://skena/entitas/selis.tscn"
const sinkron_kondisi = []

var mat1 : StandardMaterial3D
var mat2 : StandardMaterial3D
var mat3 : StandardMaterial3D
var warna_1 = Color.BLACK :
	set(ubah_warna):
		if mat1 != null: mat1.albedo_color = ubah_warna
		warna_1 = ubah_warna
var warna_2 = Color.DARK_TURQUOISE :
	set(ubah_warna):
		if mat2 != null: mat2.albedo_color = ubah_warna
		warna_2 = ubah_warna
var warna_3 = Color(0.176, 0.176, 0.176) :
	set(ubah_warna):
		if mat3 != null: mat3.albedo_color = ubah_warna
		warna_3 = ubah_warna

@export var kursi = {
	"pengemudi": -1,
	"penumpang": [-1]
}

var arah_stir : Vector2
var arah_belok : float
var batas_putaran_stir = 0.5	# persentase sudut
var kecepatan_maju = 40			# daya Watt * 10 atau m/s^2 (Newton)
var kecepatan_mundur = 10
var kecepatan_laju : Vector3
var gerakan_pandangan : Vector2 # input

@onready var torsi_kemiringan = $roda_belakang.wheel_roll_influence

func mulai() -> void:
	mat1 = $model/rangka.get_surface_override_material(0).duplicate()
	$model/rangka.set_surface_override_material(0, mat1)
	$model/rangka_lod1.set_surface_override_material(0, mat1)
	$model/rangka_lod2.set_surface_override_material(0, mat1)
	$setir/rotasi_stir/model/stir.set_surface_override_material(0, mat1)
	$setir/rotasi_stir/model/stir_lod1.set_surface_override_material(0, mat1)
	$setir/rotasi_stir/model/stir_lod2.set_surface_override_material(0, mat1)
	$model_roda_depan/translasi_model/rangka_depan.set_surface_override_material(0, mat1)
	$model_roda_depan/translasi_model/rangka_depan_lod1.set_surface_override_material(0, mat1)
	$model_roda_belakang/translasi_model/rangka_belakang.set_surface_override_material(0, mat1)
	$model_roda_belakang/translasi_model/rangka_belakang_lod1.set_surface_override_material(0, mat1)
	warna_1 = warna_1
	mat2 = $setir/rotasi_stir/model/lampu_depan.get_surface_override_material(0).duplicate()
	$setir/rotasi_stir/model/lampu_depan.set_surface_override_material(0, mat2)
	$setir/rotasi_stir/model/lampu_depan_lod1.set_surface_override_material(0, mat2)
	$setir/rotasi_stir/model/lampu_depan_lod2.set_surface_override_material(0, mat2)
	$model_roda_depan/translasi_model/spakbor_depan.set_surface_override_material(0, mat2)
	$model_roda_depan/translasi_model/spakbor_depan_lod1.set_surface_override_material(0, mat2)
	$model_roda_belakang/translasi_model/spakbor_belakang.set_surface_override_material(0, mat2)
	$model_roda_belakang/translasi_model/spakbor_belakang_lod1.set_surface_override_material(0, mat2)
	warna_2 = warna_2
	mat3 = $model/jok.get_surface_override_material(0).duplicate()
	$model/jok.set_surface_override_material(0, mat3)
	$model/jok_lod1.set_surface_override_material(0, mat3)
	$model/jok_lod2.set_surface_override_material(0, mat3)
	$setir/rotasi_stir/model/handle.set_surface_override_material(0, mat3)
	$setir/rotasi_stir/model/handle_lod1.set_surface_override_material(0, mat3)
	$setir/rotasi_stir/model/handle_lod2.set_surface_override_material(0, mat3)
	warna_3 = warna_3

func _physics_process(delta):
	if client.id_koneksi == multiplayer.get_unique_id():
		if kursi["pengemudi"] != -1 and is_instance_valid(dunia.get_node("pemain/"+str(kursi["pengemudi"]))):
			gerakan_pandangan = dunia.get_node("pemain/"+str(kursi["pengemudi"])).arah_pandangan
		
		if arah_stir.y > 0:	  	set("engine_force", kecepatan_maju * arah_stir.y)
		elif arah_stir.y < 0:	set("engine_force", kecepatan_mundur * arah_stir.y)
		else: 					set("engine_force", arah_stir.y)
		
		kecepatan_laju = get("linear_velocity") * transform.basis
		
		if arah_stir.x != 0:
			arah_belok = arah_stir.x * batas_putaran_stir
			$roda_depan.wheel_roll_influence	= torsi_kemiringan
			$roda_belakang.wheel_roll_influence = torsi_kemiringan
		else:
			if arah_stir.y != 0 and rotation.z != 0:
				rotation.z = lerp(rotation.z, 0.0, 2.0 * delta)
			arah_belok = 0
			$roda_depan.wheel_roll_influence = 0
			$roda_belakang.wheel_roll_influence = 0
		
		set("steering", move_toward(get("steering"), arah_belok, 1.5 * delta))
		$setir/rotasi_stir.rotation_degrees.y = get("steering") * 50
		
	if kursi["pengemudi"] != -1:
		if is_instance_valid(dunia.get_node("pemain/"+str(kursi["pengemudi"]))):
			if dunia.get_node("pemain/"+str(kursi["pengemudi"]))._ragdoll:
				if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
					server._gunakan_entitas(name, kursi["pengemudi"], "_berhenti_mengemudi")
				else: print_debug("ini bukan server")
			else:
				dunia.get_node("pemain/"+str(kursi["pengemudi"])).global_position = global_position
				dunia.get_node("pemain/"+str(kursi["pengemudi"])).rotation = rotation
		elif server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			server._gunakan_entitas(name, kursi["pengemudi"], "_berhenti_mengemudi")
	if kursi["penumpang"][0] != -1:
		if is_instance_valid(dunia.get_node("pemain/"+str(kursi["penumpang"][0]))):
			dunia.get_node("pemain/"+str(kursi["penumpang"][0])).global_position = global_position
			dunia.get_node("pemain/"+str(kursi["penumpang"][0])).rotation = rotation
		elif server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			server._gunakan_entitas(name, kursi["penumpang"][0], "_berhenti_menumpang")

func _process(_delta):
	if client.id_koneksi == kursi["pengemudi"]:
		if Input.is_action_pressed("maju"): 	arah_stir.y = 1
		elif Input.is_action_pressed("mundur"): arah_stir.y = -1
		else: arah_stir.y = 0
		
		if Input.is_action_pressed("berlari"):
			if Input.is_action_pressed("kiri"): 	arah_stir.x = 1;	set("axis_lock_angular_z", false)
			elif Input.is_action_pressed("kanan"):	arah_stir.x = -1;	set("axis_lock_angular_z", false)
			else: arah_stir.x = 0;				  if rotation.z == 0:	set("axis_lock_angular_z", true)
		else:
			if gerakan_pandangan.x <= -1 or gerakan_pandangan.x >= 1:
				arah_stir.x = clamp(-gerakan_pandangan.x, -1, 1);		set("axis_lock_angular_z", false)
			else: arah_stir.x = 0;				  if rotation.z == 0:	set("axis_lock_angular_z", true)
		
		if Input.is_action_pressed("lompat"):	set("brake", Input.get_action_strength("lompat"))
		elif Input.is_action_pressed("jongkok"):set("brake", Input.get_action_strength("jongkok"))
		else: set("brake", 0)

func fokus():
	if kursi["pengemudi"] == multiplayer.get_unique_id() or kursi["penumpang"][0] == multiplayer.get_unique_id():
		server.permainan.set("tombol_aksi_2", "berjalan")
	else:
		server.permainan.set("tombol_aksi_2", "naik_sepeda")
func gunakan(id_pemain):
	if kursi["pengemudi"] == id_pemain:		# pengemudi turun
		server.gunakan_entitas(name, "_berhenti_mengemudi")
		server.permainan.get_node("kontrol_sentuh/lompat").set("texture_normal", load("res://ui/tombol/lompat.svg"))
		server.permainan.set("tombol_aksi_3", "berlari")
	elif kursi["penumpang"][0] == id_pemain:# penumpang turun
		server.gunakan_entitas(name, "_berhenti_menumpang")
		server.permainan.set("tombol_aksi_3", "berlari")
	elif kursi["pengemudi"] == -1:			# naik sebagai pengemudi
		server.gunakan_entitas(name, "_kemudikan")
		server.permainan.get_node("kontrol_sentuh/lompat").set("texture_normal", load("res://ui/tombol/rem.svg"))
		server.permainan.set("tombol_aksi_3", "atur_pandangan")
	elif kursi["penumpang"][0] == -1:		# naik sebagai penumpang
		server.gunakan_entitas(name, "_menumpang")
		server.permainan.set("tombol_aksi_3", "atur_pandangan")

func _kemudikan(id_pengemudi):
	#dunia.get_node("pemain/"+str(id_pengemudi)+"/fisik").disabled = true
	dunia.get_node("pemain/"+str(id_pengemudi)).set_collision_layer_value(2, false)
	dunia.get_node("pemain/"+str(id_pengemudi)).set("gestur", "duduk")
	dunia.get_node("pemain/"+str(id_pengemudi)).set("pose_duduk", "mengendara")
	dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").set_target_node($setir/rotasi_stir/pos_tangan_kanan.get_path())
	dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").start()
	dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").set_target_node($setir/rotasi_stir/pos_tangan_kiri.get_path())
	dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").start()
	set("brake", 0)
	kursi["pengemudi"] = id_pengemudi
	#$sinkronisasi_server.set_multiplayer_authority(id_pengemudi)
	#if kursi["penumpang"][0] != -1: dunia.get_node("pemain/"+str(kursi["penumpang"][0])+"/PlayerInput").set_multiplayer_authority(client.id_koneksi)
	if client.id_koneksi == multiplayer.get_unique_id():
		server.permainan.get_node("mode_bermain").visible = false
		dunia.get_node("pemain/"+str(id_pengemudi)+"/pengamat").atur_mode(2)
		#dunia.get_node("pemain/"+str(id_pengemudi)+"/PlayerInput").kendaraan = self
func _berhenti_mengemudi(id_pengemudi):
	arah_stir = Vector2.ZERO
	set("brake", 0.25)
	if is_instance_valid(dunia.get_node("pemain/"+str(id_pengemudi))):
		dunia.get_node("pemain/"+str(id_pengemudi)).set("gestur", "berdiri")
		#dunia.get_node("pemain/"+str(id_pengemudi)+"/fisik").disabled = false
		dunia.get_node("pemain/"+str(id_pengemudi)).set_collision_layer_value(2, true)
		dunia.get_node("pemain/"+str(id_pengemudi)).rotation.x = 0
		dunia.get_node("pemain/"+str(id_pengemudi)).rotation.z = 0
		dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").set_target_node("")
		dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").stop()
		dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").set_target_node("")
		dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").stop()
	kursi["pengemudi"] = -1
	if client.id_koneksi == multiplayer.get_unique_id():
		dunia.get_node("pemain/"+str(id_pengemudi)+"/pengamat").atur_mode(1)
		#dunia.get_node("pemain/"+str(id_pengemudi)+"/PlayerInput").kendaraan = null
		server.permainan.get_node("mode_bermain").visible = true
	#$sinkronisasi_server.set_multiplayer_authority(1) 
	#if kursi["penumpang"][0] != -1: dunia.get_node("pemain/"+str(kursi["penumpang"][0])+"/PlayerInput").set_multiplayer_authority(1)
func _menumpang(id_penumpang):
	dunia.get_node("pemain/"+str(id_penumpang)).set_collision_layer_value(2, false)
	dunia.get_node("pemain/"+str(id_penumpang)).set("gestur", "duduk")
	dunia.get_node("pemain/"+str(id_penumpang)).set("pose_duduk", "dibonceng_1")
	#dunia.get_node("pemain/"+str(id_penumpang)+"/PlayerInput").set_multiplayer_authority(client.id_koneksi)
	if id_penumpang == multiplayer.get_unique_id():
		dunia.get_node("pemain/"+str(id_penumpang)+"/pengamat").atur_mode(2)
	kursi["penumpang"][0] = id_penumpang
func _berhenti_menumpang(id_penumpang):
	if is_instance_valid(dunia.get_node("pemain/"+str(id_penumpang))):
		dunia.get_node("pemain/"+str(id_penumpang)).set("gestur", "berdiri")
		dunia.get_node("pemain/"+str(id_penumpang)).set_collision_layer_value(2, true)
		dunia.get_node("pemain/"+str(id_penumpang)).rotation.x = 0
		dunia.get_node("pemain/"+str(id_penumpang)).rotation.z = 0
		#dunia.get_node("pemain/"+str(id_penumpang)+"/PlayerInput").set_multiplayer_authority(id_penumpang)
	if id_penumpang == multiplayer.get_unique_id():
		dunia.get_node("pemain/"+str(id_penumpang)+"/pengamat").atur_mode(1)
	kursi["penumpang"][0] = -1
