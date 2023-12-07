# 29/09/23
extends VehicleBody3D

@export var warna_1 = Color.BLACK :
	set(warna_baru):
		if get_node("%besi_rangka").get_surface_override_material(0) == null:
			var mtl_baru = StandardMaterial3D.new()
			get_node("%besi_rangka").set_surface_override_material(0, mtl_baru)
			get_node("%stir").set_surface_override_material(0, mtl_baru)
			get_node("%rangka_depan").set_surface_override_material(0, mtl_baru)
			get_node("%rangka_belakang").set_surface_override_material(0, mtl_baru)
		var tmp_mtl = get_node("%besi_rangka").get_surface_override_material(0)
		tmp_mtl.albedo_color = warna_baru
		warna_1 = warna_baru
@export var warna_2 = Color.DARK_TURQUOISE :
	set(warna_baru):
		if get_node("%lampu_depan").get_surface_override_material(0) == null:
			var mtl_baru = StandardMaterial3D.new()
			get_node("%lampu_depan").set_surface_override_material(0, mtl_baru)
			get_node("%spakbor_depan").set_surface_override_material(0, mtl_baru)
			get_node("%spakbor_belakang").set_surface_override_material(0, mtl_baru)
		var tmp_mtl = get_node("%lampu_depan").get_surface_override_material(0)
		tmp_mtl.albedo_color = warna_baru
		warna_2 = warna_baru
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

func _ready(): call_deferred("_setup")
func _setup():
	if get_parent().get_path() != server.permainan.dunia.get_node("entitas").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			server._tambahkan_entitas(
				"res://skena/entitas/selis.tscn",
				global_transform.origin,
				rotation,
				[
					["warna_2", Color(randf(), randf(), randf(), 1)],
					["kursi", kursi]
				]
			)
		#$sinkronisasi_server.visibility_update_mode = MultiplayerSynchronizer.VISIBILITY_PROCESS_NONE gak guna
		queue_free()

@onready var torsi_kemiringan = $roda_belakang.wheel_roll_influence
@onready var posisi_awal = global_transform.origin
@onready var rotasi_awal = rotation

func _physics_process(delta):
	if $sinkronisasi_server.get_multiplayer_authority() == multiplayer.get_unique_id():
		if kursi["pengemudi"] != -1 and is_instance_valid(server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"]))):
			gerakan_pandangan = server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"])).arah_pandangan
		
		if arah_stir.y > 0:	  engine_force = kecepatan_maju * arah_stir.y
		elif arah_stir.y < 0: engine_force = kecepatan_mundur * arah_stir.y
		else: engine_force = arah_stir.y
		
		kecepatan_laju = linear_velocity * transform.basis
		
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
		
		steering = move_toward(steering, arah_belok, 1.5 * delta)
		$setir/rotasi_stir.rotation_degrees.y = steering * 50
		
		if kursi["pengemudi"] != -1:
			if is_instance_valid(server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"]))):
				server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"])).global_position = global_position
				server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"])).rotation = rotation
			elif server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
				server._gunakan_entitas(name, kursi["pengemudi"], "_berhenti_mengemudi")
		if kursi["penumpang"][0] != -1:
			if is_instance_valid(server.permainan.dunia.get_node("pemain/"+str(kursi["penumpang"][0]))):
				server.permainan.dunia.get_node("pemain/"+str(kursi["penumpang"][0])).global_position = global_position
				server.permainan.dunia.get_node("pemain/"+str(kursi["penumpang"][0])).rotation = rotation
			elif server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
				server._gunakan_entitas(name, kursi["penumpang"][0], "_berhenti_menumpang")
		
		if global_position.y < server.permainan.batas_bawah:
			if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
				freeze = true
				angular_velocity = Vector3.ZERO
				linear_velocity  = Vector3.ZERO
				global_transform.origin = posisi_awal
				rotation		 		= rotasi_awal
				Panku.notify("re-spawn "+name)
				freeze = false
			elif server.permainan.koneksi == Permainan.MODE_KONEKSI.CLIENT:
				server.rpc_id(1, "_sesuaikan_posisi_entitas", name, client.id_koneksi)

func _process(_delta):
	if client.id_koneksi == kursi["pengemudi"]:
		if Input.is_action_pressed("maju"): 	arah_stir.y = 1
		elif Input.is_action_pressed("mundur"): arah_stir.y = -1
		else: arah_stir.y = 0
		
		if Input.is_action_pressed("berlari"):
			if Input.is_action_pressed("kiri"): 	arah_stir.x = 1;	axis_lock_angular_z = false
			elif Input.is_action_pressed("kanan"):	arah_stir.x = -1;	axis_lock_angular_z = false
			else: arah_stir.x = 0;				  if rotation.z == 0:	axis_lock_angular_z = true
		else:
			if gerakan_pandangan.x <= -1 or gerakan_pandangan.x >= 1:
				arah_stir.x = clamp(-gerakan_pandangan.x, -1, 1);		axis_lock_angular_z = false
			else: arah_stir.x = 0;				  if rotation.z == 0:	axis_lock_angular_z = true
		
		if Input.is_action_pressed("lompat"):	brake = Input.get_action_strength("lompat")
		else: brake = 0

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
	#server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/fisik").disabled = true
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set_collision_layer_value(2, false)
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set("gestur", "duduk")
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set("pose_duduk", "mengendara")
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").set_target_node($setir/rotasi_stir/pos_tangan_kanan.get_path())
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").start()
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").set_target_node($setir/rotasi_stir/pos_tangan_kiri.get_path())
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").start()
	brake = 0
	kursi["pengemudi"] = id_pengemudi
	$sinkronisasi_server.set_multiplayer_authority(id_pengemudi)
	if kursi["penumpang"][0] != -1: server.permainan.dunia.get_node("pemain/"+str(kursi["penumpang"][0])+"/PlayerInput").set_multiplayer_authority($sinkronisasi_server.get_multiplayer_authority())
	if $sinkronisasi_server.get_multiplayer_authority() == multiplayer.get_unique_id():
		server.permainan.get_node("mode_bermain").visible = false
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/pengamat").atur_mode(2)
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/PlayerInput").kendaraan = self
func _berhenti_mengemudi(id_pengemudi):
	arah_stir = Vector2.ZERO
	brake = 0.25
	if is_instance_valid(server.permainan.dunia.get_node("pemain/"+str(id_pengemudi))):
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set("gestur", "berdiri")
		#server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/fisik").disabled = false
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set_collision_layer_value(2, true)
		server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"])).rotation.x = 0
		server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"])).rotation.z = 0
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").set_target_node("")
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").stop()
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").set_target_node("")
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").stop()
	kursi["pengemudi"] = -1
	if $sinkronisasi_server.get_multiplayer_authority() == multiplayer.get_unique_id():
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/pengamat").atur_mode(1)
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/PlayerInput").kendaraan = null
		server.permainan.get_node("mode_bermain").visible = true
	$sinkronisasi_server.set_multiplayer_authority(1) 
	if kursi["penumpang"][0] != -1: server.permainan.dunia.get_node("pemain/"+str(kursi["penumpang"][0])+"/PlayerInput").set_multiplayer_authority(1)
func _menumpang(id_penumpang):
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).set_collision_layer_value(2, false)
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).set("gestur", "duduk")
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).set("pose_duduk", "dibonceng_1")
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)+"/PlayerInput").set_multiplayer_authority($sinkronisasi_server.get_multiplayer_authority())
	if id_penumpang == multiplayer.get_unique_id():
		server.permainan.dunia.get_node("pemain/"+str(id_penumpang)+"/pengamat").atur_mode(2)
	kursi["penumpang"][0] = id_penumpang
func _berhenti_menumpang(id_penumpang):
	if is_instance_valid(server.permainan.dunia.get_node("pemain/"+str(id_penumpang))):
		server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).set("gestur", "berdiri")
		server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).set_collision_layer_value(2, true)
		server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).rotation.x = 0
		server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).rotation.z = 0
		server.permainan.dunia.get_node("pemain/"+str(id_penumpang)+"/PlayerInput").set_multiplayer_authority(id_penumpang)
	if id_penumpang == multiplayer.get_unique_id():
		server.permainan.dunia.get_node("pemain/"+str(id_penumpang)+"/pengamat").atur_mode(1)
	kursi["penumpang"][0] = -1
