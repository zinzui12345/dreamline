# 29/09/23
extends entitas

const sinkron_kondisi = [
	["warna_1", Color.BLACK],
	["warna_2", Color("0dfff3")],
	["warna_3", Color(0.176, 0.176, 0.176)],
	["id_pengendara", -1],
	["id_penumpang", -1],
	["steering", 0.0],
	["engine_force", 0.0],
	["linear_velocity", Vector3.ZERO],
	["klakson", false]
]
const jalur_instance = "res://skena/entitas/selis.scn"
const abaikan_occlusion_culling = true

var efek_cahaya : GlowBorderEffectObject
var mat1 : StandardMaterial3D
var mat2 : StandardMaterial3D
var mat3 : StandardMaterial3D
var warna_1 = Color.BLACK :
	set(ubah_warna):
		if mat1 != null: mat1.albedo_color = ubah_warna
		warna_1 = ubah_warna
var warna_2 = Color.DARK_TURQUOISE :
	set(ubah_warna):
		if mat2 != null: mat2.albedo_color = ubah_warna
		warna_2 = ubah_warna
var warna_3 = Color(0.176, 0.176, 0.176) :
	set(ubah_warna):
		if mat3 != null: mat3.albedo_color = ubah_warna
		warna_3 = ubah_warna

var id_pengendara = -1:
	set(id):
		if id != -1:
			if dunia.get_node_or_null("pemain/"+str(id)) != null:
				dunia.get_node("pemain/"+str(id)).set("pose_duduk", "mengendara")
				dunia.get_node("pemain/"+str(id)).set("gestur", "duduk")
				dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").set_target_node($setir/rotasi_stir/pos_tangan_kanan.get_path())
				dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").start()
				dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").set_target_node($setir/rotasi_stir/pos_tangan_kiri.get_path())
				dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").start()
				call("add_collision_exception_with", dunia.get_node("pemain/"+str(id)))
		else:
			if dunia.get_node_or_null("pemain/"+str(id_pengendara)) != null:
				dunia.get_node("pemain/"+str(id_pengendara)).set("gestur", "berdiri")
				dunia.get_node("pemain/"+str(id_pengendara)).rotation.x = 0
				dunia.get_node("pemain/"+str(id_pengendara)).rotation.z = 0
				dunia.get_node("pemain/"+str(id_pengendara)+"/%tangan_kanan").set_target_node("")
				dunia.get_node("pemain/"+str(id_pengendara)+"/%tangan_kanan").stop()
				dunia.get_node("pemain/"+str(id_pengendara)+"/%tangan_kiri").set_target_node("")
				dunia.get_node("pemain/"+str(id_pengendara)+"/%tangan_kiri").stop()
				call("remove_collision_exception_with", dunia.get_node("pemain/"+str(id_pengendara)))
		id_pengendara = id
var id_penumpang = -1:
	set(id):
		if id != -1:
			if dunia.get_node_or_null("pemain/"+str(id)) != null:
				dunia.get_node("pemain/"+str(id)).set("pose_duduk", "dibonceng_1")
				dunia.get_node("pemain/"+str(id)).set("gestur", "duduk")
				call("add_collision_exception_with", dunia.get_node("pemain/"+str(id)))
		else:
			if dunia.get_node_or_null("pemain/"+str(id_penumpang)) != null:
				dunia.get_node("pemain/"+str(id_penumpang)).set("gestur", "berdiri")
				dunia.get_node("pemain/"+str(id_penumpang)).rotation.x = 0
				dunia.get_node("pemain/"+str(id_penumpang)).rotation.z = 0
				call("remove_collision_exception_with", dunia.get_node("pemain/"+str(id_penumpang)))
		id_penumpang = id
@export var arah_stir : Vector2
@export var arah_belok : float
@export var kecepatan_laju : Vector3
@export var klakson : bool :
	set(bunyi):
		if bunyi:	$AudioKlakson.play()
		else:		$AudioKlakson.stop()
		klakson = bunyi

const kecepatan_maju = 40			# daya Watt * 10 atau m/s^2 (Newton)
const kecepatan_mundur = 20
const batas_putaran_stir = 0.65		# persentase sudut (radian) / 37.24 (degree)
const pusat_massa_seimbang = -0.25	# posisi pusat gravitasi (y) ketika dikendarai agar tidak terjatuh ke samping
const pusat_massa_netral = -0.15	# posisi pusat gravitasi (y) pada saat diparkir
const posisi_kamera_pandangan_belakang = 3.0
const ukuran_bunyi_maksimal_akselerasi = 2.5

func mulai() -> void:
	efek_cahaya = $model
	mat1 = $model/rangka.get_surface_override_material(0).duplicate()
	$model/rangka.set_surface_override_material(0, mat1)
	$model/rangka_lod1.set_surface_override_material(0, mat1)
	$model/rangka_lod2.set_surface_override_material(0, mat1)
	$setir/rotasi_stir/model/stir.set_surface_override_material(0, mat1)
	$setir/rotasi_stir/model/stir_lod1.set_surface_override_material(0, mat1)
	$setir/rotasi_stir/model/stir_lod2.set_surface_override_material(0, mat1)
	$setir/rotasi_stir/model/pos_roda_depan/translasi_model/rangka_depan.set_surface_override_material(0, mat1)
	$setir/rotasi_stir/model/pos_roda_depan/translasi_model/rangka_depan_lod1.set_surface_override_material(0, mat1)
	$model_roda_belakang/translasi_model/rangka_belakang.set_surface_override_material(0, mat1)
	$model_roda_belakang/translasi_model/rangka_belakang_lod1.set_surface_override_material(0, mat1)
	warna_1 = warna_1
	mat2 = $setir/rotasi_stir/model/lampu_depan.get_surface_override_material(0).duplicate()
	$setir/rotasi_stir/model/lampu_depan.set_surface_override_material(0, mat2)
	$setir/rotasi_stir/model/lampu_depan_lod1.set_surface_override_material(0, mat2)
	$setir/rotasi_stir/model/lampu_depan_lod2.set_surface_override_material(0, mat2)
	$setir/rotasi_stir/model/pos_roda_depan/translasi_model/spakbor_depan.set_surface_override_material(0, mat2)
	$setir/rotasi_stir/model/pos_roda_depan/translasi_model/spakbor_depan_lod1.set_surface_override_material(0, mat2)
	$model_roda_belakang/translasi_model/spakbor_belakang.set_surface_override_material(0, mat2)
	$model_roda_belakang/translasi_model/spakbor_belakang_lod1.set_surface_override_material(0, mat2)
	warna_2 = warna_2
	mat3 = $model/jok.get_surface_override_material(0).duplicate()
	$model/jok.set_surface_override_material(0, mat3)
	$model/jok_lod1.set_surface_override_material(0, mat3)
	$model/jok_lod2.set_surface_override_material(0, mat3)
	$setir/rotasi_stir/model/handle.set_surface_override_material(0, mat3)
	$setir/rotasi_stir/model/handle_lod1.set_surface_override_material(0, mat3)
	$setir/rotasi_stir/model/handle_lod2.set_surface_override_material(0, mat3)
	warna_3 = warna_3
	id_pengendara = id_pengendara
	id_penumpang = id_penumpang

func proses(waktu_delta : float) -> void:
	if id_pengendara != -1:
		if dunia.get_node_or_null("pemain/"+str(id_pengendara)) != null:
			dunia.get_node("pemain/"+str(id_pengendara)).global_position = global_position
			dunia.get_node("pemain/"+str(id_pengendara)).rotation = rotation
	if id_penumpang != -1:
		if dunia.get_node_or_null("pemain/"+str(id_penumpang)) != null:
			dunia.get_node("pemain/"+str(id_penumpang)).global_position = global_position
			dunia.get_node("pemain/"+str(id_penumpang)).rotation = rotation
	
	if id_pengendara == client.id_koneksi and dunia.get_node_or_null("pemain/"+str(id_pengendara)) != null:
		if Input.is_action_pressed("maju"): 	arah_stir.y = Input.get_action_strength("maju")
		elif Input.is_action_pressed("mundur"): arah_stir.y = -Input.get_action_strength("mundur")
		else: arah_stir.y = 0
		
		if Input.is_action_pressed("kiri"): 	arah_stir.x = Input.get_action_strength("kiri");	#set("axis_lock_angular_z", false)
		elif Input.is_action_pressed("kanan"):	arah_stir.x = -Input.get_action_strength("kanan");	#set("axis_lock_angular_z", false)
		else: arah_stir.x = 0;				  #if rotation.z == 0:	set("axis_lock_angular_z", true)
		
		if Input.is_action_pressed("lompat"): $roda_belakang.brake = Input.get_action_strength("lompat") * 7
		else: $roda_belakang.brake = 0
		
		if arah_stir.y > 0:	  	set("engine_force", kecepatan_maju * arah_stir.y)
		elif arah_stir.y < 0:	set("engine_force", kecepatan_mundur * arah_stir.y)
		else: 					set("engine_force", arah_stir.y)
		
		kecepatan_laju = get("linear_velocity") * transform.basis
		
		# 09/05/25 :: sesuaikan audio akselerasi
		if kecepatan_laju.z > 0:
			if !$AudioAkselerasiMesin.playing: $AudioAkselerasiMesin.play()
			if kecepatan_laju.z < 2.5 and $AudioAkselerasiMesin.get("parameters/switch_to_clip") != &"kecepatan 1":
				$AudioAkselerasiMesin.set("parameters/switch_to_clip", &"kecepatan 1")
			elif kecepatan_laju.z >= 2.5 and kecepatan_laju.z < 5.5 and $AudioAkselerasiMesin.get("parameters/switch_to_clip") != &"kecepatan 2":
				$AudioAkselerasiMesin.set("parameters/switch_to_clip", &"kecepatan 2")
			elif kecepatan_laju.z >= 5.5 and kecepatan_laju.z < 15.0 and $AudioAkselerasiMesin.get("parameters/switch_to_clip") != &"kecepatan 3":
				$AudioAkselerasiMesin.set("parameters/switch_to_clip", &"kecepatan 3")
			$AudioAkselerasiMesin.unit_size = server.permainan.interpolasi(kecepatan_laju.z, 0.0, 15.0, 0.5, ukuran_bunyi_maksimal_akselerasi)
		elif $AudioAkselerasiMesin.playing: $AudioAkselerasiMesin.stop()
		
		# 01/05/25 :: kalau kecepatan_laju x 0 ~ 0.25 sesuaikan center_mass.y
		var kecepatan_belok : float = server.permainan.interpolasi(absf(kecepatan_laju.z), 0.0, 20.0, 0.0, 1.0)
		set_indexed("center_of_mass:y", server.permainan.interpolasi(absf(kecepatan_laju.x) * kecepatan_belok, 0.0, 0.25, pusat_massa_seimbang, pusat_massa_netral))
		
		if arah_stir.x != 0:
			arah_belok = arah_stir.x * batas_putaran_stir
			var persentase_rotasi = server.permainan.dapatkanNilaiPersentase(abs(get("steering")), rad_to_deg(batas_putaran_stir))
			var torsi_kemiringan : float = clamp(persentase_rotasi, 0.25, 1.0)
			$roda_depan.wheel_roll_influence	= torsi_kemiringan
			$roda_belakang.wheel_roll_influence = torsi_kemiringan
		else:
			arah_belok = 0
			var torsi_kemiringan : float = server.permainan.interpolasi(kecepatan_laju.z, 0.0, 5.0, 0.25, 1.0)
			$roda_depan.wheel_roll_influence = torsi_kemiringan
			$roda_belakang.wheel_roll_influence = torsi_kemiringan
		
		set("steering", move_toward(get("steering"), arah_belok, waktu_delta))
	
	# sesuaikan arah stir
	$setir/rotasi_stir.rotation_degrees.y = get("steering") * 50
	
	# sesuaikan translasi roda depan
	$roda_depan.global_position.x = $setir/rotasi_stir/model/pos_roda_depan.global_position.x
	$roda_depan.global_position.z = $setir/rotasi_stir/model/pos_roda_depan.global_position.z
	
	#  sesuaikan translasi shockbreaker
	$setir/rotasi_stir/model/pos_roda_depan/translasi_model.position.y = clampf($roda_depan.position.y, -0.1, 0.11)
	$model_roda_belakang/translasi_model.position.y = clampf($roda_belakang.position.y, -0.07, 0.03)

func _input(event: InputEvent) -> void:
	if id_pengendara == client.id_koneksi and dunia.get_node("pemain/"+str(id_pengendara)).kontrol:
		if Input.is_action_just_pressed("aksi1") or Input.is_action_just_pressed("aksi1_sentuh"):
			if server.permainan.get_node("kontrol_sentuh").visible and !Input.is_action_just_pressed("aksi1_sentuh"): pass # cegah pada layar sentuh, tapi tetap bisa dengan klik virtual
			else: klakson = true
		if Input.is_action_just_released("aksi1") or Input.is_action_just_released("aksi1_sentuh"):
			if server.permainan.get_node("kontrol_sentuh").visible and !Input.is_action_just_released("aksi1_sentuh"): pass # cegah pada layar sentuh, tapi tetap bisa dengan klik virtual
			else: klakson = false
		if Input.is_action_just_pressed("aksi2"):
			await get_tree().create_timer(0.1).timeout
			server.gunakan_entitas(name, "_berhenti_mengemudi")
		if Input.is_action_just_pressed("berlari"):
			dunia.get_node("pemain/"+str(id_pengendara)+"/pengamat").atur_ulang_arah_pandangan()
	
	if id_penumpang == client.id_koneksi and dunia.get_node("pemain/"+str(id_penumpang)).kontrol:
		if Input.is_action_just_pressed("aksi2"):
			await get_tree().create_timer(0.1).timeout
			server.gunakan_entitas(name, "_berhenti_menumpang")
		if Input.is_action_just_pressed("berlari"):
			dunia.get_node("pemain/"+str(id_penumpang)+"/pengamat").atur_ulang_arah_pandangan()

func fokus() -> void:
	if id_pengendara == -1 or id_penumpang == -1:
		server.permainan.set("tombol_aksi_2", "naik_sepeda")
func gunakan(id_pemain) -> void:
	if id_pengendara == id_pemain:		# pengemudi turun
		server.gunakan_entitas(name, "_berhenti_mengemudi")
	elif id_penumpang == id_pemain:		# penumpang turun
		server.gunakan_entitas(name, "_berhenti_menumpang")
	elif id_pengendara == -1:			# naik sebagai pengemudi
		server.gunakan_entitas(name, "_kemudikan")
	elif id_penumpang == -1:			# naik sebagai penumpang
		server.gunakan_entitas(name, "_menumpang")

func _kemudikan(id) -> void:
	if id == client.id_koneksi:
		dunia.raycast_occlusion_culling.add_exception(self)
		dunia.raycast_occlusion_culling.add_exception(dunia.get_node("pemain/"+str(id)))
		
		dunia.get_node("pemain/"+str(id))._atur_penarget(false)
		dunia.get_node("pemain/"+str(id)+"/pengamat").posisi_z_kustom = 0.25
		dunia.get_node("pemain/"+str(id)+"/pengamat").fokus_pandangan_belakang = $posisi_pandangan_belakang
		dunia.get_node("pemain/"+str(id)+"/pengamat").posisi_pandangan_belakang = posisi_kamera_pandangan_belakang
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_mode_kendaraan(true)
		await get_tree().create_timer(0.05).timeout		# ini untuk mencegah fungsi !_target di _process()
		
		server.permainan.set("tombol_aksi_1", "klakson_kendaraan")
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = true
		server.permainan.set("tombol_aksi_2", "berjalan")
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
		server.permainan.bantuan_aksi_2 = true
		server.permainan.set("tombol_aksi_3", "rem_sepeda")
		server.permainan.set("tombol_aksi_4", "atur_pandangan")
		
		# ubah pemroses pada server
		sinkronkan_perubahan_kondisi([["id_proses", id], ["kondisi", [["id_pengendara", id]]]])
	
	set("brake", 0)
	
	# atur id_pengendara dan id_proses
	id_pengendara = id
	id_proses = id
func _berhenti_mengemudi(id) -> void:
	arah_stir = Vector2.ZERO
	set("brake", 0.25)
	
	if id == client.id_koneksi:
		dunia.raycast_occlusion_culling.remove_exception(self)
		dunia.raycast_occlusion_culling.remove_exception(dunia.get_node("pemain/"+str(id)))
		
		dunia.get_node("pemain/"+str(id)).rotation.x = 0
		dunia.get_node("pemain/"+str(id)).rotation.z = 0
		
		dunia.get_node("pemain/"+str(id))._atur_penarget(true)
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_mode_kendaraan(false)
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_ulang_posisi_z_kustom()
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_ulang_posisi_pandangan_belakang()
		dunia.get_node("pemain/"+str(id)+"/pengamat").fokus_pandangan_belakang = null
		dunia.get_node("pemain/"+str(id)).velocity = self.linear_velocity
		dunia.get_node("pemain/"+str(id)).move_and_slide()
		
		server.permainan.set("tombol_aksi_3", "lompat")
		server.permainan.set("tombol_aksi_4", "berlari")
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		server.permainan.bantuan_aksi_1 = false
		server.permainan.bantuan_aksi_2 = false
		
		# reset pemroses pada server
		sinkronkan_perubahan_kondisi([["id_proses", id_penumpang], ["kondisi", [["id_pengendara", -1]]]])
	
	# atur ulang id_pengendara dan id_proses
	id_pengendara = -1
	id_proses = id_penumpang
func _menumpang(id) -> void:
	if id == client.id_koneksi:
		dunia.raycast_occlusion_culling.add_exception(self)
		dunia.raycast_occlusion_culling.add_exception(dunia.get_node("pemain/"+str(id)))
		
		dunia.get_node("pemain/"+str(id))._atur_penarget(false)
		dunia.get_node("pemain/"+str(id)+"/pengamat").fokus_pandangan_belakang = $posisi_pandangan_belakang
		dunia.get_node("pemain/"+str(id)+"/pengamat").posisi_pandangan_belakang = posisi_kamera_pandangan_belakang
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_mode_kendaraan(true)
		await get_tree().create_timer(0.05).timeout		# ini untuk mencegah fungsi !_target di _process()
		server.permainan.set("tombol_aksi_2", "berjalan")
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
		server.permainan.bantuan_aksi_2 = true
		server.permainan.set("tombol_aksi_4", "atur_pandangan")
		
		sinkronkan_perubahan_kondisi([["kondisi", [["id_penumpang", id]]]])
	
	# atur id_penumpang
	id_penumpang = id
func _berhenti_menumpang(id) -> void:
	if id == client.id_koneksi:
		dunia.raycast_occlusion_culling.remove_exception(self)
		dunia.raycast_occlusion_culling.remove_exception(dunia.get_node("pemain/"+str(id)))
		
		dunia.get_node("pemain/"+str(id)).rotation.x = 0
		dunia.get_node("pemain/"+str(id)).rotation.z = 0
		
		dunia.get_node("pemain/"+str(id))._atur_penarget(true)
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_mode_kendaraan(false)
		dunia.get_node("pemain/"+str(id)+"/pengamat").atur_ulang_posisi_pandangan_belakang()
		dunia.get_node("pemain/"+str(id)+"/pengamat").fokus_pandangan_belakang = null
		dunia.get_node("pemain/"+str(id)).velocity = self.linear_velocity
		dunia.get_node("pemain/"+str(id)).move_and_slide()
		
		server.permainan.set("tombol_aksi_4", "berlari")
		sinkronkan_perubahan_kondisi([["kondisi", [["id_penumpang", -1]]]])
	
	# atur id_penumpang
	id_penumpang = -1
