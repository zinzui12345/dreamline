# 25/12/23
extends entitas
class_name bunga_nektar

const jalur_instance = "res://skena/entitas/bunga_nektar.scn"
const sinkron_kondisi = [
	["total_spawn", 0],
	["data_spawn", []]
]

# TODO : refactor semuanya```
# * fungsikan(true) hanya fungsikan pada pemroses

var interval = 0.2		# interval spawn nektar # TODO : fix interval pencemaran, lalu set ini menjadi 2X dari -nya
var jumlah_spawn = 2	# jumlah maksimal nektar yang di-spawn
var data_spawn : Array 	# data nektar yang telah di-spawn
var total_spawn = 0 	# jumlah nektar yang telah di-spawn

func mulai():
	$interval_spawn.wait_time = interval * 60

func atur_pemroses(id_pemroses):
	if id_pemroses == client.id_koneksi: fungsikan(true)
	else: fungsikan(false)
func _ketika_interval_spawn():
	for n in data_spawn.size():
		if get_node_or_null(data_spawn[n-1]) == null: # FIXME : gak selamanya, bisa aja cuman berhenti di-render
			data_spawn.erase(data_spawn[n-1])
	
	if data_spawn.size() < jumlah_spawn and id_proses == client.id_koneksi:
		pass #spawn() # FIXME : fix dulu!
		#Panku.notify("spawn nektar")

func spawn():
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		server._tambahkan_entitas("res://skena/entitas/nektar.scn", $posisi_spawn.global_position, $posisi_spawn.rotation, [])
	else:
		server.rpc_id(1, "_tambahkan_entitas", "res://skena/entitas/nektar.scn", $posisi_spawn.global_position, $posisi_spawn.rotation, [])
	#data_spawn.append(nama)
	total_spawn += 1
func fungsikan(nilai: bool):
	if nilai:
		$interval_spawn.start()
		_ketika_interval_spawn()
	else:
		$interval_spawn.stop()
