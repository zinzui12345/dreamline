# 01/11/23
extends Node3D

var ketahanan = 9999			# resistansi/nyawa
var serangan = 7				# kerusakan/damage
var interval_pencemaran = 7.0	# interval pencemaran
var interval_spawn = 12.1		# interval spawn monster
var jumlah_spawn = 1			# jumlah monster yang di-spawn pada saat interval
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
	else: queue_free()
