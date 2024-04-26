# 20/12/23
extends entitas
class_name nektar

# FIXME : hancurkan ketika mengenai pencemaran

const jalur_instance = "res://skena/entitas/nektar.scn"
const sinkron_kondisi = [
	["angular_velocity", Vector3.ZERO],
	["linear_velocity", Vector3.ZERO],
	["id_pengangkat", -1]
]

# sama seperti musuh, ini di-spawn dari bunga dengan interval 2X lipat dari pencemaran
# ini gak bisa didekati musuh (npc_jamur) tapi bisa dihancurkan oleh tembakan racunnya
# pemain bisa mengangkat dan melempar ini dengan jarak rendah
# ketika dilempar;
#  jika mengenai musuh, maka musuh akan langsung mati tak peduli berapapun nyawa dan serangannya
#  kemudian ini hancur
# ketika mengenai pencemaran;
#  maka nyawa pencemaran akan dikurangi dengan nyawa * 10 ditambah dengan percepatan (velocity) [jika dilempar]
#  kemudian ini hancur
# ketika diangkat pemain;
#  kalau pemain diserang, kurangi nyawa nektar sampai hancur

var nyawa = 70
var id_pelempar = -1
var id_pengangkat = -1:
	set(id):
		if id != -1:
			set("freeze", true)
			$CollisionShape3D.disabled = true
			# otomatis set ketika pos_tangan tidak valid kemudian ready(), skrip pada pos_tangan
			if get_node_or_null("pos_tangan_kanan") != null and server.permainan.dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kanan") != null:
				# FIXME : Cannot get path of node as it is not in a scene tree.
				server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").set_target_node(get_node("pos_tangan_kanan").get_path())
				server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").start()
			if get_node_or_null("pos_tangan_kiri") != null and server.permainan.dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kiri") != null:
				# FIXME : Cannot get path of node as it is not in a scene tree.
				server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").set_target_node(get_node("pos_tangan_kiri").get_path())
				server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").start()
			call("add_collision_exception_with", server.permainan.dunia.get_node("pemain/"+str(id)))
		else:
			set("freeze", false)
			$CollisionShape3D.disabled = false
			if server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) != null:
				server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").set_target_node("")
				server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").stop()
				server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").set_target_node("")
				server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").stop()
		id_pengangkat = id

func mulai():
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		set("contact_monitor", true)
		set("max_contacts_reported", 3)
func proses(_waktu_delta : float):
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
			
			# jangan biarkan tombol lempar, lepas disable / bantuan input tersembunyi
			if !server.permainan.get_node("kontrol_sentuh/aksi_1").visible:
				server.permainan.get_node("kontrol_sentuh/aksi_1").visible = true
			if !server.permainan.get_node("kontrol_sentuh/aksi_2").visible:
				server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
			if !server.permainan.get_node("hud/bantuan_input/aksi1").visible:
				server.permainan.get_node("hud/bantuan_input/aksi1").visible = true
			if !server.permainan.get_node("hud/bantuan_input/aksi2").visible:
				server.permainan.get_node("hud/bantuan_input/aksi2").visible = true
			
			# jatuhkan jika pengangkatnya menjadi ragdoll
			if pengangkat._ragdoll:
				server.gunakan_entitas(name, "_lepas")
	elif id_pengangkat != -1 and id_proses == client.id_koneksi:
		# kalo pengangkatnya terputus, lepas
		if server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) == null:
			if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
				server._gunakan_entitas(name, -1, "_lepas")
			else:
				server.rpc("_gunakan_entitas", name, 1, "_lepas")

func fokus():
	server.permainan.set("tombol_aksi_2", "angkat_sesuatu")
func gunakan(id_pemain):
	if id_pengangkat == id_pemain:					server.gunakan_entitas(name, "_lepas")
	elif id_pengangkat == -1: 						server.gunakan_entitas(name, "_angkat")
func hapus(): # ketika tampilan dihapus
	if id_pengangkat != -1 and server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) != null:
		server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").set_target_node("")
		server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").stop()
		server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").set_target_node("")
		server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").stop()
	queue_free()
func _input(_event): # lepas walaupun tidak di-fokus
	if id_pengangkat == multiplayer.get_unique_id() and server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)).kontrol:
		if Input.is_action_just_pressed("aksi2"): await get_tree().create_timer(0.1).timeout; server.gunakan_entitas(name, "_lepas")
func _ketika_menabrak(node: Node):
	var percepatan = (get("linear_velocity") * transform.basis).abs()
	var damage = ceil((percepatan.y + percepatan.z) * 10)
	if id_pelempar != -1:
		if node != server.permainan.dunia.get_node("pemain/"+str(id_pelempar)):
			call("remove_collision_exception_with", server.permainan.dunia.get_node("pemain/"+str(id_pelempar)))
		if node is Area3D and node.get_parent() is pencemaran:
			Panku.notify("hit!") # FIXME : area nonsolid!
			node.get_parent()._diserang(
				server.permainan.dunia.get_node("pemain/"+str(id_pelempar)),
				(node.nyawa * 10) + damage
			)
			_hancur()
			server.fungsikan_objek(self.get_path(), "_hancur", [])
		elif node.get("kelompok") != null:
			match node.kelompok:
				npc_ai.grup.musuh:
					node._diserang(
						server.permainan.dunia.get_node("pemain/"+str(id_pelempar)),
						node.nyawa
					)
					_hancur()
					server.fungsikan_objek(self.get_path(), "_hancur", [])
		id_pelempar = -1
		$halangan_navigasi.avoidance_enabled = true
	# TODO : efek partikel hantam
	#print_debug(get_inverse_inertia_tensor()) # [X: (14.20119, -0, -0), Y: (-0, 14.20119, -0), Z: (-0.000001, -0, 14.20119)]
func _hancur(): # ketika hancur (musnah)
	# TODO : efek partikel hancur
	#Panku.notify("hapusss")
	hilangkan()

func _angkat(id):
	# cek id_pengangkat dengan client.id_koneksi, kalau pemain utama, jangan non-aktifkan visibilitas tombol aksi_2, non-aktifkan raycast pemain, begitupula pada _lepas()
	if id == client.id_koneksi:
		server.permainan.dunia.get_node("pemain/"+str(id)+"/PlayerInput").atur_raycast(false)
		await get_tree().create_timer(0.05).timeout		# ini untuk mencegah fungsi !_target di _process()
		server.permainan.set("tombol_aksi_1", "lempar_sesuatu")
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = true
		server.permainan.get_node("hud/bantuan_input/aksi1").visible = true
		server.permainan.set("tombol_aksi_2", "jatuhkan_sesuatu")
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
		server.permainan.get_node("hud/bantuan_input/aksi2").visible = true
		
		# ubah pemroses pada server
		var tmp_kondisi = [["id_proses", id], ["id_pengangkat", id]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	# atur id_pengangkat dan id_proses
	id_pengangkat = id
	id_proses = id
func _lepas(id):
	if server.permainan.dunia.get_node("pemain").get_node_or_null(str(id)) != null:
		call("remove_collision_exception_with", server.permainan.dunia.get_node("pemain/"+str(id)))
	call("apply_central_force", Vector3(0, 25, 50).rotated(Vector3.UP, rotation.y))
	if id == client.id_koneksi:
		server.permainan.dunia.get_node("pemain/"+str(id)+"/PlayerInput").atur_raycast(true)
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		server.permainan.get_node("hud/bantuan_input/aksi1").visible = false
		server.permainan.get_node("hud/bantuan_input/aksi2").visible = false
		
		# reset pemroses pada server
		var tmp_kondisi = [["id_proses", -1], ["id_pengangkat", -1]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	# atur ulang id_pengangkat dan id_proses
	id_pengangkat = -1
	id_proses = -1
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
	if server.permainan.dunia.get_node("pemain").get_node_or_null(str(pelempar)) != null:
		call("remove_collision_exception_with", server.permainan.dunia.get_node("pemain/"+str(pelempar)))
	call("apply_central_force", gaya.rotated(Vector3.UP, rotation.y))
	if id_pengangkat == client.id_koneksi:
		server.permainan.dunia.get_node("pemain/"+str(id_pengangkat)+"/PlayerInput").atur_raycast(true)
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		server.permainan.get_node("hud/bantuan_input/aksi1").visible = false
		server.permainan.get_node("hud/bantuan_input/aksi2").visible = false
		
		# reset pemroses pada server
		var tmp_kondisi = [["id_proses", -1], ["id_pengangkat", -1]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	# atur ulang id_pengangkat dan id_proses
	id_pengangkat = -1
	id_proses = -1
	# atur id_pelempar
	id_pelempar = pelempar
