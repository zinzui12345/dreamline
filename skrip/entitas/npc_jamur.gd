# 11/11/23
extends npc_ai

# FIXME : optimalkan performa

const posisi_bar_nyawa = 0.65

var musuh : Node3D
var target : Node3D					# node yang akan diserang
var kondisi = varian_kondisi.diam	# kondisi (state)
var _kondisi_sebelumnya				# kondisi terakhir (transisi)
var arah_pandangan = 0.0 :
	set(nilai):
		$model.rotation.y = nilai
		$fisik.rotation.y = nilai
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			$pandangan.rotation.y = nilai
			$proyektil.rotation.y = nilai
		arah_pandangan = nilai

func setup():
	$model/Skeleton3D/Mushroom.visibility_range_end = jarak_render
	$model/AnimationTree.active = true
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		$pandangan.connect("body_entered", _ketika_melihat_sesuatu)
		$pandangan.monitoring = true
		$gigit.connect("body_entered", _ketika_menggigit_sesuatu)
		$gigit.monitoring = true
	else:
		$navigasi.queue_free()
		$pandangan.queue_free()
	$proyektil.serangan = serangan
	$proyektil.penembak = get_path()

func _process(_delta):
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if _proses_navigasi:
			lihat_ke(navigasi.get_next_path_position())
		elif kondisi != varian_kondisi.menyerang and musuh != null:
			var jarak_musuh = global_transform.origin.distance_to(musuh.global_transform.origin)
			if kondisi == varian_kondisi.mengejar:
				#Panku.notify("dame!")
				if nyawa > serangan:
					if jarak_musuh > 1 and jarak_musuh <= 2:
						menyerang(musuh, "tembak")
					elif jarak_musuh <= 1:
						menyerang(musuh, "gigit")
					else:
						lihat_ke(musuh.global_transform.origin)
						navigasi_ke(musuh.global_transform.origin, true)
				elif nyawa <= serangan:
					if jarak_musuh > 10:
						navigasi_ke(musuh.global_transform.origin, true)
					elif jarak_musuh > 5:
						menyerang(musuh, "tembak")
					elif jarak_musuh <= 5:
						#Panku.notify("uwa")
						kondisi = varian_kondisi.menghindar
						_kondisi_sebelumnya = varian_kondisi.diam
			elif kondisi == varian_kondisi.menghindar:
				if jarak_musuh < 50:
					# jauhi musuh
					var arah_hindar = (global_transform.origin - musuh.global_transform.origin).normalized()
					var posisi_tujuan = global_transform.origin + arah_hindar * 100
					navigasi_ke(posisi_tujuan)
					#Panku.notify("menghindar ke :"+str(posisi_tujuan))
				else:
					# lupain musuh terus set kondisi ke diam
					musuh = null
					kondisi = varian_kondisi.diam
					#Panku.notify("lupain target")
func _ketika_berjalan(arah):
	velocity = arah
	#server.permainan.get_node("%nilai_debug").text = str(velocity.rotated(Vector3.UP, $model.rotation.y).normalized())
	if _proses_navigasi:
		$model/AnimationTree.set("parameters/gerakan/blend_position", 0)
	move_and_slide()
	# sinkronkan animasi ke pemain yang melihat
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		var pmn = server.pemain.keys()
		for p in server.pemain.size():
			if server.cek_visibilitas_entitas_terhadap_pemain(server.pemain[pmn[p]]["id_client"], self.get_path(), jarak_render):
				server.sinkronkan_properti_objek(server.pemain[pmn[p]]["id_client"], self.get_path(), "arah_pandangan", arah_pandangan)
				server.sinkronkan_properti_objek(server.pemain[pmn[p]]["id_client"], self.get_path(), "global_transform:origin", global_transform.origin)
				server.sinkronkan_properti_objek(server.pemain[pmn[p]]["id_client"], $model/AnimationTree.get_path(), "parameters/gerakan/blend_position", $model/AnimationTree.get("parameters/gerakan/blend_position"))
	else: print("[Galat] fungsi ini hanya dapat dipanggil di server!")
func _ketika_navigasi_selesai():
	if _proses_navigasi: _proses_navigasi = false
	$model/AnimationTree.set("parameters/gerakan/blend_position", -1)
	#Panku.notify("10 C")
func _ketika_melihat_sesuatu(sesuatu : Node3D):
	if sesuatu is Karakter: _ketika_melihat_pemain(sesuatu)
	elif sesuatu.get("kelompok") != null:
		match sesuatu.kelompok:
			kelompok: pass # abaikan kalau melihat sekutu
			_: # ketika melihat kelompok lain
				match kondisi:
					varian_kondisi.diam:
						if nyawa <= serangan:
							if global_transform.origin.distance_to(sesuatu.global_transform.origin) < 10:
								kondisi = varian_kondisi.menghindar
								_kondisi_sebelumnya = varian_kondisi.diam
func _ketika_melihat_pemain(pemain : Karakter):
	#Panku.notify("feel this love")
	var jarak_pemain = global_transform.origin.distance_to(pemain.global_transform.origin)
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		match kondisi:
			varian_kondisi.diam:
				if nyawa > serangan:
					if jarak_pemain <= 5:
						# TODO : hanya mengejar pemain yang membawa nektar
						musuh = pemain
						kondisi = varian_kondisi.mengejar
						_kondisi_sebelumnya = varian_kondisi.diam
						navigasi_ke(pemain.global_transform.origin, true)
					elif jarak_pemain <= 25:
						menyerang(pemain, "tembak")
func _ketika_menggigit_sesuatu(sesuatu : Node3D):
	if sesuatu.has_method("_diserang"):
		sesuatu.call("_diserang", self, serangan)
	#Panku.notify("menggigit "+sesuatu.name)

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
			"gigit":
				$model/AnimationTree.set("parameters/aksi_serang/transition_request", "menggigit")
				$model/AnimationTree.set("parameters/menyerang/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			"tembak":
				$model/AnimationTree.set("parameters/aksi_serang/transition_request", "menembak")
				$model/AnimationTree.set("parameters/menyerang/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		# sinkronkan animasi ke pemain yang melihat
		var pmn = server.pemain.keys()
		for p in server.pemain.size():
			if server.cek_visibilitas_entitas_terhadap_pemain(server.pemain[pmn[p]]["id_client"], self.get_path(), jarak_render):
				server.sinkronkan_properti_objek(server.pemain[pmn[p]]["id_client"], $model/AnimationTree.get_path(), "parameters/aksi_serang/transition_request", $model/AnimationTree.get("parameters/aksi_serang/transition_request"))
				server.sinkronkan_properti_objek(server.pemain[pmn[p]]["id_client"], $model/AnimationTree.get_path(), "parameters/menyerang/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE) # ini harus setelah transisi di-set!
	else: print("[Galat] fungsi ini hanya dapat dipanggil di server!")
func _setelah_menyerang():
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		kondisi = _kondisi_sebelumnya
		target = null
		$pandangan.monitoring = true
func _diserang(penyerang : Node3D, damage_serangan : int):
	if nyawa >= serangan:
		if nyawa > damage_serangan:
			match kondisi:
				varian_kondisi.diam:
					musuh = penyerang
					menyerang(penyerang, "tembak")
					kondisi = varian_kondisi.mengejar
					navigasi_ke(penyerang.global_transform.origin, true)
				varian_kondisi.menghindar:
					menyerang(penyerang, "tembak")
					if penyerang != musuh:
						musuh = penyerang
						kondisi = varian_kondisi.diam
						_kondisi_sebelumnya = varian_kondisi.menghindar
				
			if kondisi == varian_kondisi.mengejar:	nyawa -= ceil(damage_serangan) / 2
			else: 									nyawa -= damage_serangan
		else: mati()
	else:
		if nyawa <= damage_serangan: mati()
		else:
			_kondisi_sebelumnya = kondisi
			kondisi = varian_kondisi.menghindar
func mati():
	nyawa = 0
	musuh = null
	kondisi = varian_kondisi.mati
	_kondisi_sebelumnya = varian_kondisi.diam # FIXME : stop proses navigasi!
	#$partikel_kematian.emitting = true >> pindah ke animasinya!
	$model/AnimationTree.set("parameters/kondisi/transition_request", "mati")
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		$gigit.monitoring = false
		$pandangan.monitoring = false
		server.fungsikan_objek(self.get_path(), "mati", [])
func _setelah_mati():
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		hapus()
