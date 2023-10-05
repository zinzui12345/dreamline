# 29/09/23
extends VehicleBody3D

@export var warna_1 = Color.BLACK
@export var warna_2 = Color.DARK_TURQUOISE :
	set(warna_baru):
		if get_node("%lampu_depan").get_surface_override_material(0) == null:
			var mtl_baru = StandardMaterial3D.new()
			get_node("%lampu_depan").set_surface_override_material(0, mtl_baru)
			get_node("%spakbor_depan").set_surface_override_material(0, mtl_baru)
			get_node("%spakbor_belakang").set_surface_override_material(0, mtl_baru)
		var tmp_mtl = $setir/rotasi_stir/model/Cylinder/lampu_depan.get_surface_override_material(0)
		tmp_mtl.albedo_color = warna_baru
		warna_2 = warna_baru
@export var kursi = {
	"pengemudi": -1,
	"penumpang": [-1]
}

var arah_stir : Vector2
var arah_belok : float
var batas_putaran_stir = 0.5 # persentase sudut
var kecepatan_maju = 10	# gaya kg|m/s^2 (Newton)
var kecepatan_mundur = 5
var kecepatan_laju : Vector3

func _ready(): call_deferred("_setup")
func _setup():
	if get_parent().get_path() != server.permainan.dunia.get_node("entitas").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			server._tambahkan_entitas(
				"res://skena/entitas/selis.tscn",
				position,
				rotation,
				[
					["warna_2", Color(randf(), randf(), randf(), 1)],
					["kursi", kursi]
				]
			)
		#$MultiplayerSynchronizer.visibility_update_mode = MultiplayerSynchronizer.VISIBILITY_PROCESS_NONE gak guna
		queue_free()
func _dummy_visibility_changed(peer : int): print_debug(peer)

@onready var torsi_kemiringan = $roda_belakang.wheel_roll_influence

func _physics_process(delta):
	if arah_stir.y > 0:	  engine_force = kecepatan_maju * arah_stir.y
	elif arah_stir.y < 0: engine_force = kecepatan_mundur * arah_stir.y
	else: engine_force = arah_stir.y
	
	kecepatan_laju = linear_velocity * transform.basis
	
	if arah_stir.x != 0:
		arah_belok = arah_stir.x * batas_putaran_stir
		$roda_depan.wheel_roll_influence	= torsi_kemiringan
		$roda_belakang.wheel_roll_influence = torsi_kemiringan
	else:
		arah_belok = 0
		$roda_depan.wheel_roll_influence = 0
		$roda_belakang.wheel_roll_influence = 0
		
	#if kecepatan_laju > 5:
	#	if Input.is_action_pressed("maju") or Input.is_action_pressed("berlari-maju"):
	#		$kursi/pengemudi/rotasi_pandangan.rotation.y = lerp_angle($kursi/pengemudi/rotasi_pandangan.rotation.y, 0, 0.65*delta)
	
	steering = move_toward(steering, arah_belok, 1.5 * delta)
	$setir/rotasi_stir.rotation_degrees.y = steering * 50
	
	if kursi["pengemudi"] != -1:
		server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"])).global_position = global_position
		server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"])).rotation = rotation
	if kursi["penumpang"][0] != -1:
		server.permainan.dunia.get_node("pemain/"+str(kursi["penumpang"][0])).global_position = global_position
		server.permainan.dunia.get_node("pemain/"+str(kursi["penumpang"][0])).rotation = rotation

func _input(_event):
	if client.id_koneksi == kursi["pengemudi"]:
		if Input.is_action_pressed("maju"): 	arah_stir.y = 1
		elif Input.is_action_pressed("mundur"): arah_stir.y = -1
		else: arah_stir.y = 0
		
		if Input.is_action_pressed("kiri"): 	arah_stir.x = 1;	axis_lock_angular_z = false
		elif Input.is_action_pressed("kanan"):	arah_stir.x = -1;	axis_lock_angular_z = false
		else: arah_stir.x = 0;				  if rotation.z == 0:	axis_lock_angular_z = true
		
		if Input.is_action_pressed("lompat"):	brake = Input.get_action_strength("lompat")
		else: brake = 0

func gunakan(id_pemain):
	if kursi["pengemudi"] == id_pemain:		# pengemudi turun
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			server._gunakan_entitas(name, id_pemain, "_berhenti_mengemudi")
		else:
			server.rpc_id(1, "_gunakan_entitas", name, id_pemain, "_berhenti_mengemudi")
	elif kursi["penumpang"][0] == id_pemain:# penumpang turun
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			server._gunakan_entitas(name, id_pemain, "_berhenti_menumpang")
		else:
			server.rpc_id(1, "_gunakan_entitas", name, id_pemain, "_berhenti_menumpang")
	elif kursi["pengemudi"] == -1:			# naik sebagai pengemudi
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			server._gunakan_entitas(name, id_pemain, "_kemudikan")
		else:
			server.rpc_id(1, "_gunakan_entitas", name, id_pemain, "_kemudikan")
	elif kursi["penumpang"][0] == -1:		# naik sebagai penumpang
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			server._gunakan_entitas(name, id_pemain, "_menumpang")
		else:
			server.rpc_id(1, "_gunakan_entitas", name, id_pemain, "_menumpang")

func _kemudikan(id_pengemudi):
	#server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/fisik").disabled = true
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set_collision_layer_value(2, false)
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set("gestur", "duduk")
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/pose").set("parameters/pose_duduk/transition_request", "mengendara")
	brake = 0
	kursi["pengemudi"] = id_pengemudi
	$MultiplayerSynchronizer.set_multiplayer_authority(id_pengemudi)
	#Panku.notify("id_akses = "+str($MultiplayerSynchronizer.get_multiplayer_authority())+" <> id koneksi = "+str(multiplayer.get_unique_id())+" : "+str($MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id()))
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id(): server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/PlayerInput").kendaraan = self
func _berhenti_mengemudi(id_pengemudi):
	arah_stir = Vector2.ZERO
	brake = 0.25
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set("gestur", "berdiri")
	#server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/fisik").disabled = false
	server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set_collision_layer_value(2, true)
	server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"])).rotation.x = 0
	server.permainan.dunia.get_node("pemain/"+str(kursi["pengemudi"])).rotation.z = 0
	kursi["pengemudi"] = -1
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id(): server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/PlayerInput").kendaraan = null
	$MultiplayerSynchronizer.set_multiplayer_authority(1)
func _menumpang(id_penumpang):
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).set_collision_layer_value(2, false)
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).set("gestur", "duduk")
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)+"/pose").set("parameters/pose_duduk/transition_request", "dibonceng_1")
	kursi["penumpang"][0] = id_penumpang
func _berhenti_menumpang(id_penumpang):
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).set("gestur", "berdiri")
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).set_collision_layer_value(2, true)
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).rotation.x = 0
	server.permainan.dunia.get_node("pemain/"+str(id_penumpang)).rotation.z = 0
	kursi["penumpang"][0] = -1
