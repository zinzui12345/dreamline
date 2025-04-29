# 23/04/25
extends entitas

const abaikan_occlusion_culling = true
const jalur_instance = "res://skena/entitas/ayunan.scn"
const sinkron_kondisi = [
	["id_pengguna_1", -1],
	["id_pengguna_2", -1],
	["arah_ayunan_1", 0],
	["arah_ayunan_2", 0],
	["rotasi_ayunan_1", Vector3.ZERO],
	["rotasi_ayunan_2", Vector3.ZERO]
]

var id_pengguna_1 : int = -1:
	set(id):
		if id != -1:
			# atur kondisi pengguna
			if dunia.get_node_or_null("pemain/"+str(id)) != null:
				# sesuaikan pose pengguna
				dunia.get_node("pemain/"+str(id)).set("pose_duduk", "normal") # atur pose sebelum gestur
				dunia.get_node("pemain/"+str(id)).set("gestur", "duduk")
				
				# atur IK tangan pengguna | otomatis set ketika pos_tangan tidak valid kemudian ready(), skrip pada pos_tangan
				#if dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kanan") != null and is_inside_tree():
					#dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").set_target_node($setir/rotasi_stir/pos_tangan_kanan.get_path())
					#dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").start()
				#if dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kiri") != null and is_inside_tree():
					#dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").set_target_node($setir/rotasi_stir/pos_tangan_kiri.get_path())
					#dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").start()
			
				# nonaktifkan fisik dengan pengguna
				if id == client.id_koneksi:
					$ayunan/fisik_ayunan_1.call("add_collision_exception_with", dunia.get_node("pemain/"+str(id)))
				else:
					dunia.get_node("pemain/"+str(id))._atur_fisik(false)
				$bidang_raycast_1/batas_raycast_1.disabled = true
		else:
			if dunia.get_node("pemain").get_node_or_null(str(id_pengguna_1)) != null:
				# atur ulang pose pengguna
				dunia.get_node("pemain/"+str(id_pengguna_1)).set("gestur", "berdiri")
				
				# nonaktifkan IK tangan pengguna
				#dunia.get_node("pemain/"+str(id_pengguna_1)+"/%tangan_kanan").set_target_node("")
				#dunia.get_node("pemain/"+str(id_pengguna_1)+"/%tangan_kanan").stop()
				#dunia.get_node("pemain/"+str(id_pengguna_1)+"/%tangan_kiri").set_target_node("")
				#dunia.get_node("pemain/"+str(id_pengguna_1)+"/%tangan_kiri").stop()
				
				# aktifkan fisik dengan pengguna
				if id_pengguna_1 == client.id_koneksi:
					$ayunan/fisik_ayunan_1.call("remove_collision_exception_with", dunia.get_node("pemain/"+str(id_pengguna_1)))
				else:
					dunia.get_node("pemain/"+str(id_pengguna_1))._atur_fisik(true)
				$bidang_raycast_1/batas_raycast_1.disabled = false
		id_pengguna_1 = id
var id_pengguna_2 : int = -1:
	set(id):
		if id != -1:
			# atur kondisi pengguna
			if dunia.get_node_or_null("pemain/"+str(id)) != null:
				# sesuaikan pose pengguna
				dunia.get_node("pemain/"+str(id)).set("pose_duduk", "normal") # atur pose sebelum gestur
				dunia.get_node("pemain/"+str(id)).set("gestur", "duduk")
				
				# atur IK tangan pengguna | otomatis set ketika pos_tangan tidak valid kemudian ready(), skrip pada pos_tangan
				#if dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kanan") != null and is_inside_tree():
					#dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").set_target_node($setir/rotasi_stir/pos_tangan_kanan.get_path())
					#dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").start()
				#if dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kiri") != null and is_inside_tree():
					#dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").set_target_node($setir/rotasi_stir/pos_tangan_kiri.get_path())
					#dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").start()
			
				# nonaktifkan fisik dengan pengguna
				if id == client.id_koneksi:
					$ayunan/fisik_ayunan_2.call("add_collision_exception_with", dunia.get_node("pemain/"+str(id)))
				else:
					dunia.get_node("pemain/"+str(id))._atur_fisik(false)
				$bidang_raycast_2/batas_raycast_2.disabled = true
		else:
			if dunia.get_node("pemain").get_node_or_null(str(id_pengguna_2)) != null:
				# atur ulang pose pengguna
				dunia.get_node("pemain/"+str(id_pengguna_2)).set("gestur", "berdiri")
				
				# nonaktifkan IK tangan pengguna
				#dunia.get_node("pemain/"+str(id_pengguna_2)+"/%tangan_kanan").set_target_node("")
				#dunia.get_node("pemain/"+str(id_pengguna_2)+"/%tangan_kanan").stop()
				#dunia.get_node("pemain/"+str(id_pengguna_2)+"/%tangan_kiri").set_target_node("")
				#dunia.get_node("pemain/"+str(id_pengguna_2)+"/%tangan_kiri").stop()
				
				# aktifkan fisik dengan pengguna
				if id_pengguna_2 == client.id_koneksi:
					$ayunan/fisik_ayunan_2.call("remove_collision_exception_with", dunia.get_node("pemain/"+str(id_pengguna_2)))
				else:
					dunia.get_node("pemain/"+str(id_pengguna_2))._atur_fisik(true)
				$bidang_raycast_2/batas_raycast_2.disabled = false
		id_pengguna_2 = id
var arah_ayunan_1 : int = 0:
	set(arah):
		if arah == 0:
			$ayunan/model_ayunan_1/pos_karakter_ayunan_1.position.z = -0.171
		elif arah == 180:
			$ayunan/model_ayunan_1/pos_karakter_ayunan_1.position.z = 0.171
		$ayunan/model_ayunan_1/pos_karakter_ayunan_1.rotation_degrees.y = arah
		arah_ayunan_1 = arah
var arah_ayunan_2 : int = 0:
	set(arah):
		if arah == 0:
			$ayunan/model_ayunan_2/pos_karakter_ayunan_2.position.z = -0.171
		elif arah == 180:
			$ayunan/model_ayunan_2/pos_karakter_ayunan_2.position.z = 0.171
		$ayunan/model_ayunan_2/pos_karakter_ayunan_2.rotation_degrees.y = arah
		arah_ayunan_2 = arah
var rotasi_ayunan_1 : Vector3 = Vector3.ZERO:
	set(putaran):
		if (id_pengguna_1 != client.id_koneksi and id_pengguna_2 != client.id_koneksi) and id_proses != client.id_koneksi:
			$ayunan/fisik_ayunan_1.rotation = putaran
		$ayunan/model_ayunan_1.rotation = putaran
		rotasi_ayunan_1 = putaran
var rotasi_ayunan_2 : Vector3 = Vector3.ZERO:
	set(putaran):
		if (id_pengguna_1 != client.id_koneksi and id_pengguna_2 != client.id_koneksi) and id_proses != client.id_koneksi:
			$ayunan/fisik_ayunan_2.rotation = putaran
		$ayunan/model_ayunan_2.rotation = putaran
		rotasi_ayunan_2 = putaran

func mulai() -> void:
	id_pengguna_1 = id_pengguna_1
	id_pengguna_2 = id_pengguna_2
	arah_ayunan_1 = arah_ayunan_1
	arah_ayunan_2 = arah_ayunan_2
	rotasi_ayunan_1 = rotasi_ayunan_1
	rotasi_ayunan_2 = rotasi_ayunan_2
	set("wilayah_render", $bentuk.get_aabb())

func fokus():
	if id_pengguna_1 == -1 or id_pengguna_2 == -1:
		server.permainan.set("tombol_aksi_2", "mengayun")
func gunakan(id_pengguna) -> void:
	if id_pengguna_1 == id_pengguna:				server.gunakan_entitas(name, "_turun_dari_ayunan_1")
	elif id_pengguna_2 == id_pengguna:				server.gunakan_entitas(name, "_turun_dari_ayunan_2")
	
	elif id_pengguna_1 == -1: 						server.gunakan_entitas(name, "_naiki_ayunan_1")
	elif id_pengguna_2 == -1: 						server.gunakan_entitas(name, "_naiki_ayunan_2")

func _process(_waktu_delta : float) -> void:
	# hentikan proses jika node tidak berada dalam permainan
	if !is_instance_valid(server.permainan): set_process(false); return
	
	if id_pengguna_1 != -1 and dunia.get_node("pemain").get_node_or_null(str(id_pengguna_1)) != null:
		dunia.get_node("pemain/"+str(id_pengguna_1)).global_position = $ayunan/model_ayunan_1/pos_karakter_ayunan_1.global_position
		dunia.get_node("pemain/"+str(id_pengguna_1)).global_rotation = $ayunan/model_ayunan_1/pos_karakter_ayunan_1.global_rotation
		## sesuaikan arah pemain pada mode VR
		#if server.permainan.mode_vr and server.permainan.pengamat_vr != null:
			## 12/10/24 :: putar arah XROrigin menyesuaikan arah kendaraan
			#server.permainan.pengamat_vr.global_rotation = $arah_pengamat_vr/arah_putar/arah_pandangan.global_rotation
	if id_pengguna_2 != -1 and dunia.get_node("pemain").get_node_or_null(str(id_pengguna_2)) != null:
		dunia.get_node("pemain/"+str(id_pengguna_2)).global_position = $ayunan/model_ayunan_2/pos_karakter_ayunan_2.global_position
		dunia.get_node("pemain/"+str(id_pengguna_2)).global_rotation = $ayunan/model_ayunan_2/pos_karakter_ayunan_2.global_rotation
		## sesuaikan arah pemain pada mode VR
		#if server.permainan.mode_vr and server.permainan.pengamat_vr != null:
			## 12/10/24 :: putar arah XROrigin menyesuaikan arah kendaraan
			#server.permainan.pengamat_vr.global_rotation = $arah_pengamat_vr/arah_putar/arah_pandangan.global_rotation
	
	# sinkronkan perubahan kondisi
	if !server.mode_replay:
		if id_pengguna_1 == client.id_koneksi:
			set("rotasi_ayunan_1", $ayunan/fisik_ayunan_1.rotation)
			if id_pengguna_2 == -1 and id_proses == client.id_koneksi:
				set("rotasi_ayunan_2", $ayunan/fisik_ayunan_2.rotation)
				sinkronkan_perubahan_kondisi()
			else:
				sinkronkan_perubahan_kondisi([["kondisi", [["rotasi_ayunan_1", $ayunan/fisik_ayunan_1.rotation]]]])
		elif id_pengguna_2 == client.id_koneksi:
			set("rotasi_ayunan_2", $ayunan/fisik_ayunan_2.rotation)
			if id_pengguna_1 == -1 and id_proses == client.id_koneksi:
				set("rotasi_ayunan_1", $ayunan/fisik_ayunan_1.rotation)
				sinkronkan_perubahan_kondisi()
			else:
				sinkronkan_perubahan_kondisi([["kondisi", [["rotasi_ayunan_2", $ayunan/fisik_ayunan_2.rotation]]]])
		elif (id_pengguna_1 == -1 and id_pengguna_2 == -1) and id_proses == client.id_koneksi:
			set("rotasi_ayunan_1", $ayunan/fisik_ayunan_1.rotation)
			set("rotasi_ayunan_2", $ayunan/fisik_ayunan_2.rotation)
			sinkronkan_perubahan_kondisi()
func _input(_event): # lepas walaupun tidak di-fokus
	if id_pengguna_1 == client.id_koneksi and dunia.get_node("pemain/"+str(id_pengguna_1)).kontrol:
		if Input.is_action_just_pressed("berlari"):
			if arah_ayunan_1 == 0:
				if rotasi_ayunan_1.x > -5 and rotasi_ayunan_1.x < 35:
					$ayunan/fisik_ayunan_1.angular_velocity.x += 5
				elif $ayunan/fisik_ayunan_1.angular_velocity.x > 0:
					$ayunan/fisik_ayunan_1.angular_velocity.x += 2.5
			elif arah_ayunan_1 == 180:
				if rotasi_ayunan_1.x < 5 and rotasi_ayunan_1.x > -35:
					$ayunan/fisik_ayunan_1.angular_velocity.x -= 5
				elif $ayunan/fisik_ayunan_1.angular_velocity.x < 0:
					$ayunan/fisik_ayunan_1.angular_velocity.x -= 2.5
		if Input.is_action_just_pressed("lompat"):
			if rotasi_ayunan_1.x > -35 and rotasi_ayunan_1.x < 35:
				$ayunan/fisik_ayunan_1.angular_velocity.x = lerpf($ayunan/fisik_ayunan_1.angular_velocity.x, 0.0, 2)
		if Input.is_action_just_pressed("aksi2"):
			await get_tree().create_timer(0.1).timeout; server.gunakan_entitas(name, "_turun_dari_ayunan_1")
	elif id_pengguna_2 == client.id_koneksi and dunia.get_node("pemain/"+str(id_pengguna_2)).kontrol:
		if Input.is_action_just_pressed("berlari"):
			if arah_ayunan_2 == 0:
				if rotasi_ayunan_2.x > -5 and rotasi_ayunan_2.x < 35:
					$ayunan/fisik_ayunan_2.angular_velocity.x += 5
				elif $ayunan/fisik_ayunan_2.angular_velocity.x > 0:
					$ayunan/fisik_ayunan_2.angular_velocity.x += 2.5
			elif arah_ayunan_2 == 180:
				if rotasi_ayunan_2.x < 5 and rotasi_ayunan_2.x > -35:
					$ayunan/fisik_ayunan_2.angular_velocity.x -= 5
				elif $ayunan/fisik_ayunan_2.angular_velocity.x < 0:
					$ayunan/fisik_ayunan_2.angular_velocity.x -= 2.5
		if Input.is_action_just_pressed("lompat"):
			if rotasi_ayunan_2.x > -35 and rotasi_ayunan_2.x < 35:
				$ayunan/fisik_ayunan_2.angular_velocity.x = lerpf($ayunan/fisik_ayunan_2.angular_velocity.x, 0.0, 2)
		if Input.is_action_just_pressed("aksi2"):
			await get_tree().create_timer(0.1).timeout; server.gunakan_entitas(name, "_turun_dari_ayunan_2")

func _naiki_ayunan_1(id):
	# atur pengguna
	if id == client.id_koneksi:
		dunia.raycast_occlusion_culling.add_exception(self)
		dunia.raycast_occlusion_culling.add_exception(dunia.get_node("pemain/"+str(id)))
		
		dunia.get_node("pemain/"+str(id))._atur_penarget(false)
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_mode(2)
		await get_tree().create_timer(0.05).timeout		# ini untuk mencegah fungsi !_target di _process()
		server.permainan.set("tombol_aksi_2", "berjalan")
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
		server.permainan.bantuan_aksi_2 = true
		server.permainan.set("tombol_aksi_4", "mengayun")
		
		# atur arah_ayunan berdasarkan arah pemain
		if absf(global_rotation_degrees.y - dunia.get_node("pemain/"+str(id)).global_rotation_degrees.y) > 90:
			arah_ayunan_1 = 180
		else:
			arah_ayunan_1 = 0
		
		## atur arah pemain pada mode VR
		#if server.permainan.mode_vr and server.permainan.pengamat_vr != null:
			#$arah_pengamat_vr.global_rotation = server.permainan.pengamat_vr.global_rotation
			#if server.permainan.pengamat_vr.get_node("XRCamera3D").rotation_degrees.y > 0:
				#var arah_putar = $arah_pengamat_vr.rotation_degrees.y + absf(server.permainan.pengamat_vr.get_node("XRCamera3D").rotation_degrees.y)
				#if $arah_pengamat_vr.rotation_degrees.y < 0:
					#$arah_pengamat_vr/arah_putar.rotation_degrees.y = global_rotation.y - arah_putar
				#else:
					#$arah_pengamat_vr/arah_putar.rotation_degrees.y = -arah_putar
			#else:
				#var arah_putar = $arah_pengamat_vr.rotation_degrees.y - absf(server.permainan.pengamat_vr.get_node("XRCamera3D").rotation_degrees.y)
				#if $arah_pengamat_vr.rotation_degrees.y > 0:
					#$arah_pengamat_vr/arah_putar.rotation_degrees.y = global_rotation.y - arah_putar
				#else:
					#$arah_pengamat_vr/arah_putar.rotation_degrees.y = -arah_putar
		
		# ubah pemroses pada server
		sinkronkan_perubahan_kondisi([["id_proses", id], ["kondisi", [["id_pengguna_1", id], ["arah_ayunan_1", arah_ayunan_1]]]])
	
	# atur id_pengguna_1 dan id_proses
	id_pengguna_1 = id
	id_proses = id
func _naiki_ayunan_2(id):
	# atur pengguna
	if id == client.id_koneksi:
		dunia.raycast_occlusion_culling.add_exception(self)
		dunia.raycast_occlusion_culling.add_exception(dunia.get_node("pemain/"+str(id)))
		
		dunia.get_node("pemain/"+str(id))._atur_penarget(false)
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_mode(2)
		await get_tree().create_timer(0.05).timeout		# ini untuk mencegah fungsi !_target di _process()
		server.permainan.set("tombol_aksi_2", "berjalan")
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
		server.permainan.bantuan_aksi_2 = true
		server.permainan.set("tombol_aksi_4", "mengayun")
		
		# atur arah_ayunan berdasarkan arah pemain
		if absf(global_rotation_degrees.y - dunia.get_node("pemain/"+str(id)).global_rotation_degrees.y) > 90:
			arah_ayunan_2 = 180
		else:
			arah_ayunan_2 = 0
		
		## atur arah pemain pada mode VR
		#if server.permainan.mode_vr and server.permainan.pengamat_vr != null:
			#$arah_pengamat_vr.global_rotation = server.permainan.pengamat_vr.global_rotation
			#if server.permainan.pengamat_vr.get_node("XRCamera3D").rotation_degrees.y > 0:
				#var arah_putar = $arah_pengamat_vr.rotation_degrees.y + absf(server.permainan.pengamat_vr.get_node("XRCamera3D").rotation_degrees.y)
				#if $arah_pengamat_vr.rotation_degrees.y < 0:
					#$arah_pengamat_vr/arah_putar.rotation_degrees.y = global_rotation.y - arah_putar
				#else:
					#$arah_pengamat_vr/arah_putar.rotation_degrees.y = -arah_putar
			#else:
				#var arah_putar = $arah_pengamat_vr.rotation_degrees.y - absf(server.permainan.pengamat_vr.get_node("XRCamera3D").rotation_degrees.y)
				#if $arah_pengamat_vr.rotation_degrees.y > 0:
					#$arah_pengamat_vr/arah_putar.rotation_degrees.y = global_rotation.y - arah_putar
				#else:
					#$arah_pengamat_vr/arah_putar.rotation_degrees.y = -arah_putar
		
		# ubah pemroses pada server
		sinkronkan_perubahan_kondisi([["id_proses", id], ["kondisi", [["id_pengguna_2", id], ["arah_ayunan_2", arah_ayunan_2]]]])
	
	# atur id_pengguna_2 dan id_proses
	id_pengguna_2 = id
	id_proses = id

func _turun_dari_ayunan_1(id):
	# atur pengguna
	if id == client.id_koneksi:
		dunia.raycast_occlusion_culling.remove_exception(self)
		dunia.raycast_occlusion_culling.remove_exception(dunia.get_node("pemain/"+str(id)))
		
		dunia.get_node("pemain/"+str(id)).rotation.x = 0
		dunia.get_node("pemain/"+str(id)).rotation.z = 0
		
		dunia.get_node("pemain/"+str(id))._atur_penarget(true)
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_mode(1)
		
		server.permainan.set("tombol_aksi_4", "berlari")
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		server.permainan.bantuan_aksi_2 = false
		
		## atur ulang arah pemain pada mode VR
		#if server.permainan.mode_vr and server.permainan.pengamat_vr != null:
			#server.permainan.pengamat_vr.rotation = Vector3.ZERO
			#$arah_pengamat_vr/arah_putar.rotation_degrees.y = 0
		
		# reset pemroses pada server
		sinkronkan_perubahan_kondisi([["id_proses", id_pengguna_2], ["kondisi", [["id_pengguna_1", -1]]]])
	
	# atur ulang id_pengguna_1 dan id_proses
	id_pengguna_1 = -1
	id_proses = id_pengguna_2
func _turun_dari_ayunan_2(id):
	# atur pengguna
	if id == client.id_koneksi:
		dunia.raycast_occlusion_culling.remove_exception(self)
		dunia.raycast_occlusion_culling.remove_exception(dunia.get_node("pemain/"+str(id)))
		
		dunia.get_node("pemain/"+str(id)).rotation.x = 0
		dunia.get_node("pemain/"+str(id)).rotation.z = 0
		
		dunia.get_node("pemain/"+str(id))._atur_penarget(true)
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_mode(1)
		
		server.permainan.set("tombol_aksi_4", "berlari")
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		server.permainan.bantuan_aksi_2 = false
		
		## atur ulang arah pemain pada mode VR
		#if server.permainan.mode_vr and server.permainan.pengamat_vr != null:
			#server.permainan.pengamat_vr.rotation = Vector3.ZERO
			#$arah_pengamat_vr/arah_putar.rotation_degrees.y = 0
		
		# reset pemroses pada server
		sinkronkan_perubahan_kondisi([["id_proses", id_pengguna_1], ["kondisi", [["id_pengguna_2", -1]]]])
	
	# atur ulang id_pengguna_2 dan id_proses
	id_pengguna_2 = -1
	id_proses = id_pengguna_1
