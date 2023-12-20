# 20/12/23
extends RigidBody3D
 
class_name nektar

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

@onready var posisi_awal = global_transform.origin
@onready var rotasi_awal = rotation

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
