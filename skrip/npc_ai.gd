# 03/11/23
extends CharacterBody3D

var _proses_navigasi = false

enum grup {
	pemain,		# + teman, mis: hewan 
	netral,		# = hewan liar
	musuh		# - monster
}

var nyawa = 100
var serangan = 25
var kelompok = grup.netral
var kecepatan_gerak = 5

@onready var navigasi : NavigationAgent3D = $navigasi

## setup ##
func _ready():
	# FIXME : ini nantinya cuma di server
	navigasi.avoidance_enabled = true
	navigasi.connect("velocity_computed", _ketika_berjalan)
	navigasi.connect("navigation_finished", _ketika_navigasi_selesai)

## core ##
# arahkan untuk pergi ke posisi tertentu
func navigasi_ke(posisi : Vector3, berlari = false):
	navigasi.set_target_position(posisi)
	_proses_navigasi = true

# ketika diserang dengan nilai serangan tertentu
func serang(id_penyerang, serangan : int):
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

# ketika sampai di posisi tujuan
func _ketika_navigasi_selesai():
	if _proses_navigasi:
		Panku.notify("why!?"+str(velocity))
		_proses_navigasi = false

## debug ##
func _input(_event):
	if Input.is_action_just_pressed("daftar_pemain"): navigasi_ke(server.permainan.karakter.global_position)
