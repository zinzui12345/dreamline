# 01/11/23
extends Node3D

class_name pencemaran

var ketahanan = 9999			# resistansi/nyawa
var serangan = 7				# kerusakan/damage
var interval_pencemaran = 7		# interval pencemaran
var interval_spawn = 0.1		# interval spawn monster | 12
var jumlah_spawn = 4			# jumlah maksimal monster yang di-spawn
var total_spawn = 0				# jumlah monster yang telah di-spawn
var radius_pencemaran = 0.3		# jarak penambahan area pencemaran di tiap interval

# pada tiap interval pencemaran;
#  luas area_pencemaran akan bertambah dengan nilai radius_pencemaran selama luas area_pencemaran < 100
#  jika dalam radius < 100 terdapat bunga_nektar, maka luas area_pencemaran tidak akan bertambah
#  jika luas area_pencemaran >= 100, maka tambahkan 1 jumlah_spawn selama jumlah_spawn < 7
#  ketika pemain/hewan teman/hewan netral berada dalam area, maka akan mendapat serangan
# pada tiap interval spawn akan memunculkan monster random sebanyak jumlah_spawn di posisi random dalam area_pencemaran jika jarak pemain dekat | < 100
# ketika diserang;
#  ketahanan dikurangi dengan jumlah serangan_penyerang selama ketahanan > 0
#  luas area_pencemaran akan berkurang dengan jumlah (serangan_penyerang * radius_pencemaran) selama luas area_pencemaran > 1

func _ready():
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		server.objek[str(get_path())] = \
		{
			"pemilik": 0,
			"sumber": "res://skena/entitas/pencemaran.scn",
			"global_transform:origin": global_transform.origin,
			"rotation_degrees": rotation_degrees
		}
		
		$area_pencemaran.monitoring = true
		$area_pencemaran.monitorable = true
		$interval_pencemaran.wait_time = interval_pencemaran * 60
		$interval_spawn.wait_time = interval_spawn * 60
		$interval_pencemaran.start()
		$interval_spawn.start()
		
		_ketika_interval_spawn()
	elif server.objek.has(str(get_path())): pass
	else: queue_free()

func _ketika_interval_pencemaran(): pass
func _ketika_interval_spawn():
	if $spawn_npc.get_child_count() < jumlah_spawn and server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		total_spawn += 1
		spawn(Vector3.ZERO, "npc_jamur_"+str(total_spawn))
		server.fungsikan_objek(self.get_path(), "spawn", [Vector3.ZERO, "npc_jamur_"+str(total_spawn)])
		# TODO : navigasi ke posisi random berdasarkan radius shape area_pencemaran
		# TODO : efek partikel spawn
		#Panku.notify("spawn .")

func spawn(_posisi : Vector3, nama : StringName):
	var tmp_musuh = load("res://skena/entitas/npc_jamur.scn").instantiate()
	tmp_musuh.name = nama
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.CLIENT: # node harus terdaftar di server.objek supaya gak kehapus
		server.objek[str($spawn_npc.get_path())+"/"+tmp_musuh.name] = \
			{
				"pemilik": 1,
				"sumber": "res://skena/entitas/npc_jamur.scn",
				"global_transform:origin": global_transform.origin,
				"rotation_degrees": rotation_degrees
			}
	$spawn_npc.add_child(tmp_musuh)
