# 17/11/23
extends Node3D

var _peluru_ditembak = {} # TODO : ini daftar untuk di sinkron

var peluru : RigidBody3D
var kecepatan : float = 40.0

func _ready():
	$peluru.visible = false
	$fisik_peluru.freeze = true

func tembakkan():
	var model = $peluru.duplicate()
	var fisik = $fisik_peluru.duplicate()
	var arah_tembakan = global_transform.basis.z.normalized() * kecepatan
	
	fisik.name = "peluru_"+str(server.permainan.dunia.get_node("entitas").get_child_count())+"_"+str(_peluru_ditembak.size())
	server.permainan.dunia.get_node("entitas").add_child(fisik)
	
	fisik.global_transform.basis = $peluru.global_transform.basis
	fisik.global_transform.origin = $peluru.global_transform.origin
	
	model.visible = true
	fisik.add_child(model)
	
	fisik.freeze = false
	fisik.linear_velocity = arah_tembakan
	
	fisik.get_node("f").disabled = false

func hapus_peluru(nama : StringName):
	# gimana caranya menggil ke sini sedangkan parent-nya bukan ini???
	server.permainan.dunia.get_node("entitas").remove_child(
		server.permainan.dunia.get_node("entitas").get_node(nama)
	)
