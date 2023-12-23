# 20/12/23
extends RigidBody3D
 
class_name nektar

# FIXME : hancurkan ketika mengenai musuh atau pencemaran

var nyawa = 70
var id_pelempar = -1

@export var id_pengangkat = -1:
	set(id):
		if id != -1:
			freeze = true
			$CollisionShape3D.disabled = true
			$MultiplayerSynchronizer.set_multiplayer_authority(id)
			server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").set_target_node($pos_tangan_kanan.get_path())
			server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").start()
			server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").set_target_node($pos_tangan_kiri.get_path())
			server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").start()
			add_collision_exception_with(server.permainan.dunia.get_node("pemain/"+str(id)))
		else:
			freeze = false
			$CollisionShape3D.disabled = false
			$MultiplayerSynchronizer.set_multiplayer_authority(1)
			if server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) != null:
				server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").set_target_node("")
				server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").stop()
				server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").set_target_node("")
				server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").stop()
		id_pengangkat = id

# sama seperti musuh, ini di-spawn dari bunga dengan interval 2X lipat dari pencemaran
# ini gak bisa didekati musuh (npc_jamur) tapi bisa dihancurkan oleh tembakan racunnya
# pemain bisa mengangkat dan melempar ini dengan jarak rendah
# ketika dilempar;
#  jika mengenai musuh, maka musuh akan langsung mati tak peduli berapapun nyawa dan serangannya
#  kemudian ini hancur
# ketika mengenai pencemaran;
#  maka nyawa pencemaran akan dikurangi dengan nyawa * 10 ditambah dengan percepatan (velocity) [jika dilempar]
#  kemudian ini hancur

func _ready(): call_deferred("_setup")
func _setup():
	if get_parent().get_path() != server.permainan.dunia.get_node("entitas").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			server._tambahkan_entitas(
				"res://skena/entitas/nektar.scn",
				global_transform.origin,
				rotation,
				[]
			)
		queue_free()
	elif server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		contact_monitor = true
		max_contacts_reported = 3

@onready var posisi_awal = global_transform.origin
@onready var rotasi_awal = rotation

func _process(_delta):
	if id_pengangkat != -1 and id_pengangkat == client.id_koneksi:
		if is_instance_valid(server.permainan.dunia.get_node("pemain/"+str(id_pengangkat))):
			var pengangkat = server.permainan.dunia.get_node("pemain/"+str(id_pengangkat))
			
			# attach posisi ke pemain
			global_transform.origin = pengangkat.get_node("%pinggang").global_transform.origin
			global_rotation = pengangkat.get_node("%pinggang").global_rotation
			
			# input kendali
			if pengangkat.kontrol:
				if Input.is_action_just_pressed("aksi1") or Input.is_action_just_pressed("aksi1_sentuh"):
					if server.permainan.get_node("kontrol_sentuh").visible and !Input.is_action_just_pressed("aksi1_sentuh"): pass # cegah pada layar sentuh, tapi tetap bisa dengan klik virtual
					else: server.gunakan_entitas(name, "_lempar")
			
			# jangan biarkan tombol lepas disable
			if !server.permainan.get_node("kontrol_sentuh/aksi_2").visible:
				server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
			
			# jatuhkan jika pengangkatnya menjadi ragdoll
			if pengangkat._ragdoll:
				server.gunakan_entitas(name, "_lepas")
	elif id_pengangkat != -1 and server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		# kalo pengangkatnya terputus, lepas
		if server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) == null:
			server._gunakan_entitas(name, 1, "_lepas")
func _physics_process(delta):
	if global_position.y < server.permainan.batas_bawah: # atur ulang kalau jatuh ke void
		if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
			freeze = true
			angular_velocity = Vector3.ZERO
			linear_velocity  = Vector3.ZERO
			global_transform.origin = posisi_awal
			rotation		 		= rotasi_awal
			Panku.notify("re-spawn "+name)
			freeze = false
		elif server.permainan.koneksi == Permainan.MODE_KONEKSI.CLIENT:
			server.rpc_id(1, "_sesuaikan_posisi_entitas", name, client.id_koneksi)
func _ketika_menabrak(node: Node):
	var percepatan = (linear_velocity * transform.basis).abs()
	#var damage = ceil((percepatan.y + percepatan.z) * 10)
	if id_pelempar != -1:
		if node != server.permainan.dunia.get_node("pemain/"+str(id_pelempar)):
			remove_collision_exception_with(server.permainan.dunia.get_node("pemain/"+str(id_pelempar)))
		if node.get("kelompok") != null:
			match node.kelompok:
				npc_ai.grup.musuh:
					node._diserang(
						server.permainan.dunia.get_node("pemain/"+str(id_pelempar)),
						node.nyawa
					)
					server.fungsikan_objek(self.get_path(), "_hancur", [])
		id_pelempar = -1
		$halangan_navigasi.avoidance_enabled = true
	# TODO : efek partikel hantam
func _input(_event): # lepas walaupun tidak di-fokus
	if id_pengangkat == multiplayer.get_unique_id() and server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)).kontrol:
		if Input.is_action_just_pressed("aksi2"): await get_tree().create_timer(0.1).timeout; server.gunakan_entitas(name, "_lepas")
func _hancur(): # ketika hancur (musnah)
	# TODO : efek partikel hancur
	pass

func fokus():
	server.permainan.set("tombol_aksi_2", "angkat_sesuatu")
func gunakan(id_pemain):
	if id_pengangkat == id_pemain:					server.gunakan_entitas(name, "_lepas")
	elif id_pengangkat == -1: 						server.gunakan_entitas(name, "_angkat")

func _angkat(id):
	# cek id_pengangkat dengan client.id_koneksi, kalau pemain utama, jangan non-aktifkan visibilitas tombol aksi_2, non-aktifkan raycast pemain, begitupula pada _lepas()
	if id_pengangkat == client.id_koneksi:
		server.permainan.dunia.get_node("pemain/"+str(id)+"/PlayerInput").atur_raycast(false)
		await get_tree().create_timer(0.05).timeout		# ini untuk mencegah fungsi !_target di _process()
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
	id_pengangkat = id
func _lepas(id):
	if server.permainan.dunia.get_node("pemain").get_node_or_null(str(id)) != null:
		remove_collision_exception_with(server.permainan.dunia.get_node("pemain/"+str(id)))
	apply_central_force(Vector3(0, 25, 50).rotated(Vector3.UP, rotation.y))
	if id == client.id_koneksi:
		server.permainan.dunia.get_node("pemain/"+str(id)+"/PlayerInput").atur_raycast(true)
	id_pengangkat = -1
func _lempar(pelempar):
	var kekuatan = 400
	if server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) != null:
		rotation.y = server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)).rotation.y
		rotation.x = server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%pandangan").rotation.x
		# jumpshoot!
		if server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)).lompat:
			kekuatan = kekuatan * 2
			$halangan_navigasi.avoidance_enabled = false
		if server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)).arah_gerakan.y > 1:
			kekuatan = kekuatan * server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)).arah_gerakan.y
			$halangan_navigasi.avoidance_enabled = false
	var gaya : Vector3 = Vector3(0, 0, kekuatan).rotated(Vector3.LEFT, rotation.x)
	apply_central_force(gaya.rotated(Vector3.UP, rotation.y))
	if id_pengangkat == client.id_koneksi:
		server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/PlayerInput").atur_raycast(true)
	id_pengangkat = -1
	id_pelempar = pelempar
