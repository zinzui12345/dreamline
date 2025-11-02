# 29/09/23
extends Vehicle

const sinkron_kondisi = [
	["warna_1", Color.BLACK],
	["warna_2", Color("0dfff3")],
	["warna_3", Color(0.176, 0.176, 0.176)],
	["id_pengendara", -1],
	["id_penumpang", -1],
	["steering_input", 0.0],
	["throttle_input", 0.0],
	["brake_input", 0.0],
	["handbrake_input", 0.0],
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
				dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").set_target_node($model/transformasi_setir/setir/rotasi_stir/pos_tangan_kanan.get_path())
				dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").start()
				dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").set_target_node($model/transformasi_setir/setir/rotasi_stir/pos_tangan_kiri.get_path())
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

@export var arah_belok : float
@export var klakson : bool :
	set(bunyi):
		if bunyi:	$model/transformasi_setir/setir/rotasi_stir/AudioKlakson.play()
		else:		$model/transformasi_setir/setir/rotasi_stir/AudioKlakson.stop()
		klakson = bunyi

const posisi_kamera_pandangan_belakang = 3.0

func mulai() -> void:
	efek_cahaya = $model
	mat1 = $model/rangka.get_surface_override_material(0).duplicate()
	$model/rangka.set_surface_override_material(0, mat1)
	$model/rangka_lod1.set_surface_override_material(0, mat1)
	$model/rangka_lod2.set_surface_override_material(0, mat1)
	$model/transformasi_setir/setir/rotasi_stir/model/stir.set_surface_override_material(0, mat1)
	$model/transformasi_setir/setir/rotasi_stir/model/stir_lod1.set_surface_override_material(0, mat1)
	$model/transformasi_setir/setir/rotasi_stir/model/stir_lod2.set_surface_override_material(0, mat1)
	$model/transformasi_setir/setir/suspensi_depan/posisi_suspensi_depan/model_suspensi_depan/rangka_depan.set_surface_override_material(0, mat1)
	$model/transformasi_setir/setir/suspensi_depan/posisi_suspensi_depan/model_suspensi_depan/rangka_depan_lod1.set_surface_override_material(0, mat1)
	$model/transformasi_roda_belakang/suspensi_belakang/model_suspensi_belakang/rangka_belakang.set_surface_override_material(0, mat1)
	$model/transformasi_roda_belakang/suspensi_belakang/model_suspensi_belakang/rangka_belakang_lod1.set_surface_override_material(0, mat1)
	warna_1 = warna_1
	mat2 = $model/transformasi_setir/setir/rotasi_stir/model/lampu_depan.get_surface_override_material(0).duplicate()
	$model/transformasi_setir/setir/rotasi_stir/model/lampu_depan.set_surface_override_material(0, mat2)
	$model/transformasi_setir/setir/rotasi_stir/model/lampu_depan_lod1.set_surface_override_material(0, mat2)
	$model/transformasi_setir/setir/rotasi_stir/model/lampu_depan_lod2.set_surface_override_material(0, mat2)
	$model/transformasi_setir/setir/suspensi_depan/posisi_suspensi_depan/model_suspensi_depan/spakbor_depan.set_surface_override_material(0, mat2)
	$model/transformasi_setir/setir/suspensi_depan/posisi_suspensi_depan/model_suspensi_depan/spakbor_depan_lod1.set_surface_override_material(0, mat2)
	$model/transformasi_roda_belakang/suspensi_belakang/model_suspensi_belakang/spakbor_belakang.set_surface_override_material(0, mat2)
	$model/transformasi_roda_belakang/suspensi_belakang/model_suspensi_belakang/spakbor_belakang_lod1.set_surface_override_material(0, mat2)
	warna_2 = warna_2
	mat3 = $model/jok.get_surface_override_material(0).duplicate()
	$model/jok.set_surface_override_material(0, mat3)
	$model/jok_lod1.set_surface_override_material(0, mat3)
	$model/jok_lod2.set_surface_override_material(0, mat3)
	$model/transformasi_setir/setir/rotasi_stir/model/handle.set_surface_override_material(0, mat3)
	$model/transformasi_setir/setir/rotasi_stir/model/handle_lod1.set_surface_override_material(0, mat3)
	$model/transformasi_setir/setir/rotasi_stir/model/handle_lod2.set_surface_override_material(0, mat3)
	warna_3 = warna_3
	id_pengendara = id_pengendara
	id_penumpang = id_penumpang
	call("initialize")

func proses(_waktu_delta : float) -> void:
	if id_pengendara != -1:
		if dunia.get_node_or_null("pemain/"+str(id_pengendara)) != null:
			dunia.get_node("pemain/"+str(id_pengendara)).global_position = $model.global_position
			dunia.get_node("pemain/"+str(id_pengendara)).global_rotation = $model.global_rotation
	if id_penumpang != -1:
		if dunia.get_node_or_null("pemain/"+str(id_penumpang)) != null:
			dunia.get_node("pemain/"+str(id_penumpang)).global_position = $model.global_position
			dunia.get_node("pemain/"+str(id_penumpang)).global_rotation = $model.global_rotation
	
	if id_pengendara == client.id_koneksi and dunia.get_node_or_null("pemain/"+str(id_pengendara)) != null:
		if current_gear == -1:
			throttle_input = Input.get_action_strength("mundur")
			brake_input = Input.get_action_strength("maju")
		else:
			throttle_input = pow(Input.get_action_strength("maju"), 2.0)
			brake_input = Input.get_action_strength("mundur")
		
		arah_belok = (Input.get_action_strength("kiri") + Input.get_action_strength("pandangan_kiri")) - (Input.get_action_strength("kanan") + Input.get_action_strength("pandangan_kanan"))
		steering_input = clampf(arah_belok, -1.0, 1.0)
		
		handbrake_input = Input.get_action_strength("lompat")
		
		if arah_belok != 0.0:	enable_stability = false
		elif !enable_stability:	enable_stability = true

func _input(_event: InputEvent) -> void:
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
	
	handbrake_input = 0
	
	# atur id_pengendara dan id_proses
	id_pengendara = id
	id_proses = id
func _berhenti_mengemudi(id) -> void:
	steering_input = 0.0
	handbrake_input = 0.25
	
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
