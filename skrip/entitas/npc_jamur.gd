# 11/11/23
extends npc_ai

# FIXME : optimalkan performa

enum varian_kondisi {
	diam,		# idle / keliling
	mengejar,	# menarget musuh
	menyerang,	# menyerang musuh
	menghindar	# menjauh dari musuh
}

var musuh : Node3D
var target : Node3D					# node yang akan diserang
var kondisi = varian_kondisi.diam	# kondisi (state)
var _kondisi_sebelumnya				# kondisi terakhir (transisi)
var arah_pandangan = 0.0 :
	set(nilai):
		$model.rotation.y = nilai
		$fisik.rotation.y = nilai
		$pandangan.rotation.y = nilai
		$proyektil.rotation.y = nilai
		arah_pandangan = nilai

func setup():
	$model/Skeleton3D/Mushroom.visibility_range_end = jarak_render
	$model/AnimationTree.active = true
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		$pandangan.connect("body_entered", _ketika_melihat_sesuatu)
		$pandangan.monitoring = true
	else:
		$navigasi.queue_free()
		$pandangan.queue_free()
	$proyektil.serangan = serangan

func _process(delta):
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if _proses_navigasi:
			lihat_ke(navigasi.get_next_path_position())
func _ketika_berjalan(arah):
	velocity = arah
	#server.permainan.get_node("%nilai_debug").text = str(velocity.rotated(Vector3.UP, $model.rotation.y).normalized())
	if _proses_navigasi:
		$model/AnimationTree.set("parameters/gerakan/blend_position", 0)
	move_and_slide()
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		var pmn = server.pemain.keys()
		for p in server.pemain.size():
			if server.cek_visibilitas_entitas_terhadap_pemain(server.pemain[pmn[p]]["id_client"], self.get_path(), jarak_render):
				server.atur_properti_objek(self.get_path(), "global_transform:origin", global_transform.origin)
				server.atur_properti_objek(self.get_path(), "arah_pandangan", arah_pandangan)
	else: print("[Galat] fungsi ini hanya dapat dipanggil di server!")
func _ketika_navigasi_selesai():
	if _proses_navigasi: _proses_navigasi = false
	$model/AnimationTree.set("parameters/gerakan/blend_position", -1)
	#Panku.notify("10 C")
func _ketika_melihat_sesuatu(sesuatu : Node3D):
	if sesuatu is Karakter: _ketika_melihat_pemain(sesuatu)
func _ketika_melihat_pemain(pemain : Karakter):
	#Panku.notify("feel this love")
	var jarak_pemain = global_transform.origin.distance_to(pemain.global_transform.origin)
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		match kondisi:
			varian_kondisi.diam:
				if nyawa > serangan:
					if jarak_pemain <= 5:
						musuh = pemain
						kondisi = varian_kondisi.mengejar
						_kondisi_sebelumnya = varian_kondisi.diam
					elif jarak_pemain <= 50:
						menyerang(pemain, "tembak")
			# TODO : pindah ke _ketika_melihat_sesuatu()
			#	elif nyawa < serangan:
			#		ketika ada kelompok lain dengan jarak < 20
			#			ubah kondisi menjadi menghindar
			#		pass
			# varian_kondisi.mengejar:
			#	if nyawa > serangan:
			#		pass

func lihat_ke(posisi : Vector3):
	$model.look_at(posisi, Vector3.UP, true)
	$model.rotation.x = 0
	arah_pandangan = $model.rotation.y
func menyerang(target_serangan : Node3D, tipe_serangan : StringName):
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		_kondisi_sebelumnya = kondisi
		target = target_serangan
		kondisi = varian_kondisi.menyerang
		$pandangan.set_deferred("monitoring", false)
		lihat_ke(target_serangan.global_transform.origin)
		match tipe_serangan:
			"gigit": pass
			"tembak":
				$model/AnimationTree.set("parameters/aksi_serang/transition_request", "menembak")
				$model/AnimationTree.set("parameters/menyerang/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	else: print("[Galat] fungsi ini hanya dapat dipanggil di server!")
func _setelah_menembak_racun():
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		# TODO : pindah ke node racun yang ditembakkan
		# if target.has_method("serang"):
		# 	target.call("serang", serangan)
		kondisi = _kondisi_sebelumnya
		target = null
		$pandangan.monitoring = true
