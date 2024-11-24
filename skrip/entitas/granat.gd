extends entitas

const sinkron_kondisi = []
const jalur_instance = "res://skena/entitas/granat.scn"
const radius_ledakan : int = 10
const jarak_lod1 : int = 3
const jarak_lod2 : int = 15

var id_pengangkat : int = -1:
	set(id):
		if id != -1:
			set("freeze", true)
			$fisik.disabled = true
			# otomatis set ketika pos_tangan tidak valid kemudian ready(), skrip pada pos_tangan
			if get_node_or_null("pos_tangan_kanan") != null and get_node_or_null("pos_tangan_kanan").is_inside_tree() and dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kanan") != null:
				dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").set_target_node(get_node("pos_tangan_kanan").get_path())
				dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").start()
			call("add_collision_exception_with", dunia.get_node("pemain/"+str(id)))
		else:
			set("freeze", false)
			$fisik.disabled = false
			if dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) != null:
				dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").set_target_node("")
				dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").stop()
		id_pengangkat = id
var id_pelempar : int = -1
var timer_ledakan : Timer

func _ready(): call_deferred("_setup")
func _setup():
	if get_parent().get_path() != dunia.get_node("entitas").get_path():
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and not server.mode_replay:
			server._tambahkan_entitas(
				"res://skena/entitas/senjata_granat.scn",
				global_transform.origin,
				rotation,
				[
					[ "id_pengangkat", -1 ],
					[ "id_pelempar", -1 ]
				]
			)
		queue_free()
	else:
		timer_ledakan = Timer.new()
		timer_ledakan.name = "timer_ledakan"
		add_child(timer_ledakan)
		timer_ledakan.one_shot = true
		timer_ledakan.wait_time = 3
		timer_ledakan.connect("timeout", _ketika_meledak)
		for ch in $model.get_children():
			if ch is MeshInstance3D:
				if ch.name.ends_with("_detail"):
					ch.visibility_range_end = jarak_lod1
					ch.visible = true
				elif ch.name.ends_with("_lod1"):
					ch.visibility_range_begin = jarak_lod1
					ch.visibility_range_end = jarak_lod2
					ch.visible = true
				elif ch.name.ends_with("_lod2"):
					ch.visibility_range_begin = jarak_lod2
					ch.visible = true
				else:
					ch.visibility_range_end = jarak_lod2

func proses(_waktu_delta : float) -> void:
	if !is_instance_valid(server.permainan): set_process(false); return
	
	if id_pengangkat != -1:
		if id_pengangkat == client.id_koneksi:
			if id_pelempar == -1 and dunia.get_node_or_null("pemain/"+str(id_pengangkat)) != null:
				var tmp_id_pengangkat = id_pengangkat # 18/07/24 :: id_pengangkat harus dijadiin konstan, kalau nggak pada akhir eksekusi nilainya bisa -1
				var tmp_pos_angkat = dunia.get_node("pemain/"+str(tmp_id_pengangkat)+"/%kepala").position + $posisi_angkat.position.rotated(Vector3(1, 0, 0), dunia.get_node("pemain/"+str(tmp_id_pengangkat)+"/%kepala").rotation.x)
				
				# attach posisi ke pemain
				# 12/10/24 :: jangan pake transformasi global, karena posisi gak sesuai di mode pandangan first person
				global_position = dunia.get_node("pemain/"+str(tmp_id_pengangkat)).global_position + dunia.get_node("pemain/"+str(tmp_id_pengangkat)).transform.basis * tmp_pos_angkat
				global_rotation = dunia.get_node("pemain/"+str(tmp_id_pengangkat)).global_rotation + $posisi_angkat.transform.basis * dunia.get_node("pemain/"+str(tmp_id_pengangkat)+"/%kepala").rotation
				
				# input kendali
				if dunia.get_node("pemain/"+str(tmp_id_pengangkat)).kontrol:
					if Input.is_action_just_pressed("aksi1") or Input.is_action_just_pressed("aksi1_sentuh"):
						if server.permainan.get_node("kontrol_sentuh").visible and !Input.is_action_just_pressed("aksi1_sentuh"): pass # cegah pada layar sentuh, tapi tetap bisa dengan klik virtual
						else: server.gunakan_entitas(name, "_lempar")
				
				# jangan biarkan tombol lempar, lepas disable / bantuan input tersembunyi
				if !server.permainan.get_node("kontrol_sentuh/aksi_1").visible:
					server.permainan.get_node("kontrol_sentuh/aksi_1").visible = true
				if !server.permainan.get_node("kontrol_sentuh/aksi_2").visible:
					server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
				if !server.permainan.bantuan_aksi_1: server.permainan.bantuan_aksi_1 = true
				if !server.permainan.bantuan_aksi_2: server.permainan.bantuan_aksi_2 = true
				
				# jatuhkan jika pengangkatnya menjadi ragdoll
				if dunia.get_node("pemain/"+str(tmp_id_pengangkat))._ragdoll:
					server.gunakan_entitas(name, "_lepas")
		elif server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			# kalo pengangkatnya terputus, lepas # FIXME : pool gimana caranya???
			if dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) == null:
				server._gunakan_entitas(name, 1, "_lepas")

func fokus():
	server.permainan.set("tombol_aksi_2", "angkat_sesuatu")
func gunakan(id_pemain):
	if id_pengangkat == id_pemain:					server.gunakan_entitas(name, "_lepas")
	elif id_pengangkat == -1: 						server.gunakan_entitas(name, "_angkat")

func _input(_event):
	if id_pengangkat == client.id_koneksi and dunia.get_node("pemain/"+str(id_pengangkat)).kontrol:
		if Input.is_action_just_pressed("aksi2"): await get_tree().create_timer(0.1).timeout; server.gunakan_entitas(name, "_lepas")
func _ketika_menabrak(node: Node):
	if $fisik_ledakan.disable_mode == false:
		var percepatan = (get("linear_velocity") * transform.basis).abs()
		var damage = ceil((percepatan.y + percepatan.z) * 10)
		#Panku.notify("kirru! : "+node.name+" <== " + str(damage))
		if id_pelempar != -1 and node.has_method("_diserang"):
			node.call("_diserang", dunia.get_node("pemain/"+str(id_pelempar)), damage)
func _ketika_meledak():
	set("freeze", true)
	$model.visible = false
	$fisik_ledakan/AnimationPlayer.play("meledak")
	#Panku.notify("explosion!!")
	await $fisik_ledakan/AnimationPlayer.animation_finished
	if id_pengangkat == client.id_koneksi:
		server.gunakan_entitas(name, "_lepas")
	if id_proses == client.id_koneksi:
		server.hapus_objek(self.get_path())

func _angkat(id):
	# cek id_pengangkat dengan client.id_koneksi, kalau pemain utama, jangan non-aktifkan visibilitas tombol aksi_2, non-aktifkan raycast pemain, begitupula pada _lepas()
	if id == client.id_koneksi:
		dunia.get_node("pemain/"+str(id))._atur_penarget(false)
		await get_tree().create_timer(0.05).timeout		# ini untuk mencegah fungsi !_target di _process()
		server.permainan.set("tombol_aksi_1", "lempar_sesuatu")
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = true
		server.permainan.bantuan_aksi_1 = true
		server.permainan.set("tombol_aksi_2", "jatuhkan_sesuatu")
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
		server.permainan.bantuan_aksi_2 = true
		
		# ubah pemroses pada server
		var tmp_kondisi = [["id_proses", id], ["id_pengangkat", id]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	# atur id_pengangkat dan id_proses
	id_pengangkat = id
	id_pelempar = -1
	id_proses = id
func _lepas(id):
	$model.visible = true
	# terapkan percepatan
	server.terapkan_percepatan_objek(
		get_path(),
		Vector3(0, 0.5, 1).rotated(Vector3.UP, rotation.y)
	)
	# atur pengecualian tabrakan
	if id == client.id_koneksi and dunia.get_node_or_null("pemain/"+str(id)) != null:
		call("remove_collision_exception_with", dunia.get_node("pemain/"+str(id)))
		dunia.get_node("pemain/"+str(id))._atur_penarget(true)
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.bantuan_aksi_1 = false
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		server.permainan.bantuan_aksi_2 = false
		
		# reset pemroses pada server
		var tmp_kondisi = [["id_proses", -1], ["id_pengangkat", -1]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		set("contact_monitor", false)
		set("max_contacts_reported", 0)
	# atur ulang id_pengangkat, id_pelempar dan id_proses
	id_pengangkat = -1
	id_pelempar = -1
	id_proses = -1
func _lempar(_pelempar):
	var kekuatan = 8
	# sesuaikan rotasi global dengan arah pandangan pelempar
	rotation.x = dunia.get_node("pemain/"+str(_pelempar)+"/%pandangan").rotation.x # FIXME : sinkronkan rotasi pandangan pemain
	# jumpshoot!
	if dunia.get_node("pemain/"+str(_pelempar)).melompat:
		kekuatan = kekuatan * 2
	if dunia.get_node("pemain/"+str(_pelempar)).arah_gerakan.y > 1:
		kekuatan = kekuatan * dunia.get_node("pemain/"+str(_pelempar)).arah_gerakan.y
	var gaya : Vector3 = Vector3(0, 0, kekuatan).rotated(Vector3.LEFT, rotation.x)
	server.terapkan_percepatan_objek(
		get_path(),
		gaya.rotated(Vector3.UP, rotation.y)
	)
	if _pelempar == client.id_koneksi and dunia.get_node_or_null("pemain/"+str(_pelempar)) != null:
		call("remove_collision_exception_with", (dunia.get_node("pemain/"+str(_pelempar))))
		dunia.get_node("pemain/"+str(_pelempar))._atur_penarget(true)
		dunia.get_node("pemain/"+str(_pelempar)).objek_target = self
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.bantuan_aksi_1 = false
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		server.permainan.bantuan_aksi_2 = false
		
		# reset pemroses pada server
		var tmp_kondisi = [["id_proses", -1], ["id_pengangkat", -1], ["id_pelempar", _pelempar]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		set("contact_monitor", false)
		set("max_contacts_reported", 0)
	# atur ulang id_pengangkat, id_pelempar dan id_proses
	id_pengangkat = -1
	id_pelempar = _pelempar
	id_proses = -1
	timer_ledakan.start()

func hapus():
	if id_pengangkat != -1 and dunia.get_node("pemain").get_node_or_null(str(id_pengangkat)) != null:
		dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").set_target_node("")
		dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kanan").stop()
		dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").set_target_node("")
		dunia.get_node("pemain/"+str(id_pengangkat)+"/%tangan_kiri").stop()
	queue_free()
