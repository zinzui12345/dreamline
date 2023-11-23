# 17/11/23
extends Node3D

# TODO : opsi arah_tembakan.y berdasarkan jarak target | lemparan
# TODO : muat resource (MeshInstance3D) peluru sebagai peluru

@export var peluru : Resource
@export var penembak : NodePath
@export var serangan : int

var _peluru_ditembak : Dictionary = {}
var kecepatan : float = 40.0

func _ready():
	$peluru.visible = false
	$fisik_peluru.freeze = true

func tembakkan():
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		var model = $peluru.duplicate()
		var fisik = $fisik_peluru.duplicate()
		var arah_tembakan = global_transform.basis.z.normalized() * kecepatan
		var id_peluru : int = server.permainan.dunia.get_node("entitas").get_child_count()
		var nama_peluru = "peluru_"+str(id_peluru)+"_"+str(_peluru_ditembak.size())
	
		fisik.name = nama_peluru
		server.permainan.dunia.get_node("entitas").add_child(fisik)
		
		fisik.global_transform.basis = $peluru.global_transform.basis
		fisik.global_transform.origin = $peluru.global_transform.origin
		
		model.visible = true
		fisik.add_child(model)
		
		fisik.freeze = false
		fisik.linear_velocity = arah_tembakan
		
		fisik.get_node("f").disabled = false
		fisik.id = id_peluru
		fisik.jalur_proyektil = get_path()
		fisik.jalur_penembak = penembak
		fisik.damage_serangan = serangan
		
		_peluru_ditembak[str(id_peluru)] = {
			"nama":		nama_peluru,
			"arah":		fisik.global_transform.basis,
			"posisi":	fisik.global_transform.origin
		}
		
		rpc("buat_tampilan", nama_peluru)

func hapus_peluru(id : int):
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and server.permainan.dunia.get_node_or_null("entitas/"+str(_peluru_ditembak[str(id)].nama)) != null:
		server.permainan.dunia.get_node("entitas/"+str(_peluru_ditembak[str(id)].nama)).queue_free()
		_peluru_ditembak.erase(id)
		rpc("hapus_tampilan", str(_peluru_ditembak[str(id)].nama))

func sinkronisasi_peluru(id):
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		rpc("sinkronkan_tampilan", _peluru_ditembak[str(id)].nama, _peluru_ditembak[str(id)].arah, _peluru_ditembak[str(id)].posisi)

@rpc func buat_tampilan(nama):
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.CLIENT:
		var model = $peluru.duplicate()
		model.name = nama
		model.visible = true
		server.permainan.dunia.get_node("entitas").add_child(model)
@rpc func sinkronkan_tampilan(nama : StringName, arah : Basis, posisi : Vector3):
	var node_peluru = server.permainan.dunia.get_node_or_null("entitas/"+nama)
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.CLIENT and node_peluru != null:
		node_peluru.global_transform.basis = arah
		node_peluru.global_transform.origin = posisi
@rpc func hapus_tampilan(nama : StringName):
	var node_peluru = server.permainan.dunia.get_node_or_null("entitas/"+nama)
	# FIXME : kadang dihapus bersamaan ketika server menambah ulang dengan nama yang sama
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.CLIENT and node_peluru != null:
		node_peluru.name = node_peluru.name+"_israel_babi"
		node_peluru.queue_free()
