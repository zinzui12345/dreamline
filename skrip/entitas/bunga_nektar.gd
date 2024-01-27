# 25/12/23
extends Node3D

class_name bunga_nektar

var interval = 0.2		# interval spawn nektar # TODO : fix interval pencemaran, lalu set ini menjadi 2X dari -nya
var jumlah_spawn = 2	# jumlah maksimal nektar yang di-spawn
var data_spawn : Array 	# data nektar yang telah di-spawn
var total_spawn = 0 	# jumlah nektar yang telah di-spawn

func _ready():
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		server.objek[str(get_path())] = \
		{
			"pemilik": 0,
			"sumber": "res://skena/entitas/bunga_nektar.scn",
			"global_transform:origin": global_transform.origin,
			"rotation_degrees": rotation_degrees
		}
		
		$interval_spawn.wait_time = interval * 60
		
		#fungsikan(true) # TODO : hanya fungsikan pada pemain tertentu yang berada pada satu potongan
	elif server.objek.has(str(get_path())): pass
	else: queue_free()

func _ketika_interval_spawn():
	for n in data_spawn.size():
		if get_node_or_null(data_spawn[n-1]) == null:
			data_spawn.erase(data_spawn[n-1])
	
	if data_spawn.size() < jumlah_spawn and server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		spawn(Vector3.ZERO, str(get_path())+":nektar_"+str(total_spawn))
		#Panku.notify("spawn nektar")

func spawn(_posisi : Vector3, nama : StringName):
	var tmp_nektar : Node3D = load("res://skena/entitas/nektar.scn").instantiate()
	tmp_nektar.name = nama
	server.permainan.dunia.get_node("entitas").add_child(tmp_nektar)
	tmp_nektar.global_position = $posisi_spawn.global_position
	tmp_nektar.posisi_awal = $posisi_spawn.global_position
	data_spawn.append(str(tmp_nektar.get_path()))
	total_spawn += 1
func fungsikan(nilai: bool):
	if nilai:
		$interval_spawn.start()
		_ketika_interval_spawn()
	else:
		$interval_spawn.stop()
