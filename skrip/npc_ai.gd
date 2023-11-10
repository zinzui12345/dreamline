# 03/11/23
extends CharacterBody3D

var _proses_navigasi = false

enum grup {
	pemain,		# + teman, mis: hewan 
	netral,		# = hewan liar
	musuh		# - monster
}

@export var jalur_skena = "res://skena/npc_ai.tscn"
@export var nyawa = 100
@export var serangan = 25
@export var kelompok = grup.netral
@export var kecepatan_gerak = 2

@onready var navigasi : NavigationAgent3D = $navigasi

## setup ##
func _ready():
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		server.objek[str(get_path())] = \
		{
			"pemilik": 1,
			"sumber": jalur_skena,
			"global_transform:origin": global_transform.origin,
			"rotation_degrees": rotation_degrees
		}
		navigasi.avoidance_enabled = true
		navigasi.connect("velocity_computed", _ketika_berjalan)
		navigasi.connect("navigation_finished", _ketika_navigasi_selesai)
	elif server.objek.has(str(get_path())): pass
	else: queue_free()

## core ##
# arahkan untuk pergi ke posisi tertentu
func navigasi_ke(posisi : Vector3, berlari = false):
	navigasi.set_target_position(posisi)
	_proses_navigasi = true

# ketika diserang dengan nilai serangan tertentu
func serang(id_penyerang, damage_serangan : int):
	pass

## event ##
# proses navigasi
func _physics_process(delta):
	if _proses_navigasi:
		var posisi_selanjutnya = navigasi.get_next_path_position()
		var posisi_saat_ini = global_position
		var arah = (posisi_selanjutnya - posisi_saat_ini).normalized() * kecepatan_gerak
		if navigasi.avoidance_enabled:
			navigasi.set_velocity(arah)
		else:
			_ketika_berjalan(arah)
	elif velocity != Vector3.ZERO:
		velocity.x = lerpf(velocity.x, 0, kecepatan_gerak * delta)
		velocity.z = lerpf(velocity.z, 0, kecepatan_gerak * delta)
	move_and_slide()

# arah ketika berjalan
func _ketika_berjalan(arah):
	velocity = arah
	move_and_slide()
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		var pmn = server.pemain.keys()
		for p in server.pemain.size():
			if server.cek_visibilitas_entitas_terhadap_pemain(server.pemain[pmn[p]]["id_client"], self.get_path()):
				server.atur_properti_objek(self.get_path(), "global_transform:origin", global_transform.origin)
				server.atur_properti_objek(self.get_path(), "rotation_degrees", rotation_degrees)
				Panku.notify("pemain "+str(pmn[p])+" melihat npc_ai")
 
# ketika sampai di posisi tujuan
func _ketika_navigasi_selesai():
	if _proses_navigasi:
		_proses_navigasi = false

## debug ##
func _input(_event):
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if Input.is_action_just_pressed("daftar_pemain"): navigasi_ke(server.permainan.karakter.global_position)
