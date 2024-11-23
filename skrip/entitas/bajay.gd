# 11/07/21
extends entitas

const radius_tabrak : int = 10
const sinkron_kondisi = [
	["warna_1", Color("FFF")],
	["warna_2", Color("3900ff")],
	["warna_3", Color("ff0021")],
	["warna_4", Color("ff5318")],
	["warna_5", Color("000000")],
	["id_pengemudi", -1],
	["steering", 0.0],
	["engine_force", 0.0],
	["klakson", false]
]
const jalur_instance = "res://skena/entitas/bajay.tscn"
const batas_putaran_stir = 0.5

var id_pengemudi = -1:
	set(id):
		if id != -1:
			# atur kondisi pengemudi
			if server.permainan.dunia.get_node_or_null("pemain/"+str(id)) != null:
				# sesuaikan pose pengemudi
				server.permainan.dunia.get_node("pemain/"+str(id)).set("gestur", "duduk")
				server.permainan.dunia.get_node("pemain/"+str(id)).set("pose_duduk", "mengemudi")
				
				# atur IK tangan pengemudi | otomatis set ketika pos_tangan tidak valid kemudian ready(), skrip pada pos_tangan
				if server.permainan.dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kanan") != null and is_inside_tree():
					server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").set_target_node($setir/rotasi_stir/pos_tangan_kanan.get_path())
					server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kanan").start()
				if server.permainan.dunia.get_node_or_null("pemain/"+str(id)+"/%tangan_kiri") != null and is_inside_tree():
					server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").set_target_node($setir/rotasi_stir/pos_tangan_kiri.get_path())
					server.permainan.dunia.get_node("pemain/"+str(id)+"/%tangan_kiri").start()
			
			# aktifkan audio
			$AudioMesin.play()
			$AudioAkselerasiMesin.volume_db = -30
			
			# nonaktifkan fisik dengan pengemudi
			call("add_collision_exception_with", server.permainan.dunia.get_node("pemain/"+str(id)))
		else:
			if server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengemudi)) != null:
				# atur ulang pose pengemudi
				server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).set("gestur", "berdiri")
				
				# nonaktifkan IK tangan pengemudi
				server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").set_target_node("")
				server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").stop()
				server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").set_target_node("")
				server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").stop()
				
				# nonaktifkan audio
				#$AudioMesin.stream.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED) # ini belum bisa, jadi pake $AudioHentikanMesin
				$AudioHentikanMesin.play()
				$AudioMesin.stop()
				var tween_volume_akselerasi = get_tree().create_tween()
				tween_volume_akselerasi.tween_property($AudioAkselerasiMesin, "volume_db", -30, 1)
				tween_volume_akselerasi.tween_property($AudioAkselerasiMesin, "pitch_scale", 0.7, 1)
				tween_volume_akselerasi.tween_callback($AudioAkselerasiMesin.stop)
				tween_volume_akselerasi.play()
				
				# aktifkan fisik dengan pengemudi
				call("remove_collision_exception_with", server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)))
		id_pengemudi = id
var arah_kemudi : Vector2
var arah_belok : float
var rem : bool
var klakson : bool :
	set(bunyi):
		if bunyi:	$AudioKlakson.play()
		else:		$AudioKlakson.stop()
		klakson = bunyi
var kecepatan_normal : int = 80
var kecepatan_maksimal : int = 150
var kecepatan_mundur : int = 60
var kekuatan_mesin : int = kecepatan_normal
var kekuatan_rem : int = 3
var kecepatan_laju : float = 0
var percepatan : float

var mat1 : StandardMaterial3D
var mat2 : StandardMaterial3D
var mat3 : StandardMaterial3D
var mat4 : StandardMaterial3D
var mat5 : StandardMaterial3D

var warna_1 : Color = Color("FFF"):
	set(ubah_warna):
		if mat1 != null: mat1.albedo_color = ubah_warna
		warna_1 = ubah_warna
var warna_2 : Color = Color("3900ff"):
	set(ubah_warna):
		if mat2 != null: mat2.albedo_color = ubah_warna
		warna_2 = ubah_warna
var warna_3 : Color = Color("ff0021"):
	set(ubah_warna):
		if mat3 != null: mat3.albedo_color = ubah_warna
		warna_3 = ubah_warna
var warna_4 : Color :
	set(ubah_warna):
		if mat4 != null: mat4.albedo_color = ubah_warna
		warna_4 = ubah_warna
var warna_5 : Color :
	set(ubah_warna):
		if mat5 != null: mat5.albedo_color = ubah_warna
		warna_5 = ubah_warna

# fungsi yang akan dipanggil pada saat node memasuki SceneTree menggantikan _ready()
func mulai() -> void:
	mat1 = $model/detail/bodi.get_surface_override_material(0).duplicate()
	mat2 = $model/detail/bodi.get_surface_override_material(1).duplicate()
	mat3 = $model/detail/bodi.get_surface_override_material(10).duplicate()
	mat4 = $model/detail/bodi.get_surface_override_material(5).duplicate()
	mat5 = $model/detail/bodi.get_surface_override_material(11).duplicate()
	warna_1 = warna_1
	warna_2 = warna_2
	warna_3 = warna_3
	warna_4 = warna_4
	warna_5 = warna_5
	$model/detail/bodi.set_surface_override_material(0, mat1)
	$model/lod1/bodi_lod1.set_surface_override_material(0, mat1)
	$model/detail/bodi.set_surface_override_material(1, mat2)
	$model/lod1/bodi_lod1.set_surface_override_material(1, mat2)
	$model/detail/bodi.set_surface_override_material(10, mat3)
	$model/lod1/bodi_lod1.set_surface_override_material(8, mat3)
	$model/detail/bodi.set_surface_override_material(5, mat4)
	$model/detail/bodi.set_surface_override_material(11, mat5)
	$model/lod1/bodi_lod1.set_surface_override_material(9, mat5)
	$model/detail/subreker_depan.set_surface_override_material(0, mat5)
	$model/detail/subreker_depan_lod1.set_surface_override_material(0, mat5)
	id_pengemudi = id_pengemudi
# fungsi yang akan dipanggil setiap saat menggantikan _process(delta)
func proses(waktu_delta : float) -> void:
	if id_pengemudi != -1 and server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengemudi)) != null:
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).global_position = global_position
		server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).rotation = rotation
		# sesuaikan arah pemain pada mode VR
		if server.permainan.mode_vr and server.permainan.pengamat_vr != null:
			# 12/10/24 :: putar arah XROrigin menyesuaikan arah kendaraan
			server.permainan.pengamat_vr.global_rotation = $arah_pengamat_vr/arah_putar/arah_pandangan.global_rotation
	
	if id_pengemudi == multiplayer.get_unique_id():
		if arah_kemudi.y > 0:	set("engine_force", kekuatan_mesin * arah_kemudi.y)
		elif arah_kemudi.y < 0:	set("engine_force", kecepatan_mundur * arah_kemudi.y)
		else:					set("engine_force", arah_kemudi.y)
		
		kecepatan_laju = (self.linear_velocity * transform.basis).z
		
		if arah_kemudi.x != 0:
			arah_belok = arah_kemudi.x * batas_putaran_stir
		else:
			arah_belok = 0
		
		self.steering = move_toward(self.steering, arah_belok, 1.5 * waktu_delta)
		$setir/rotasi_stir.rotation_degrees.y = self.steering * 110
	if id_pengemudi != -1:
		_atur_audio_mesin(waktu_delta)
		percepatan = kecepatan_laju
func _input(_event): # lepas walaupun tidak di-fokus
	if id_pengemudi == multiplayer.get_unique_id() and server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).kontrol:
		if Input.is_action_just_pressed("aksi1") or Input.is_action_just_pressed("aksi1_sentuh"):
			if server.permainan.get_node("kontrol_sentuh").visible and !Input.is_action_just_pressed("aksi1_sentuh"): pass # cegah pada layar sentuh, tapi tetap bisa dengan klik virtual
			else: klakson = true
		if Input.is_action_just_released("aksi1") or Input.is_action_just_released("aksi1_sentuh"):
			if server.permainan.get_node("kontrol_sentuh").visible and !Input.is_action_just_released("aksi1_sentuh"): pass # cegah pada layar sentuh, tapi tetap bisa dengan klik virtual
			else: klakson = false
		if Input.is_action_just_pressed("aksi2"):
			await get_tree().create_timer(0.1).timeout; server.gunakan_entitas(name, "_lepas")
		
		if Input.is_action_pressed("maju"): 	arah_kemudi.y = Input.get_action_strength("maju")
		elif Input.is_action_pressed("mundur"):	arah_kemudi.y = -Input.get_action_strength("mundur")
		else:									arah_kemudi.y = 0
		
		if Input.is_action_pressed("kiri"):		arah_kemudi.x = Input.get_action_strength("kiri")
		elif Input.is_action_pressed("kanan"):	arah_kemudi.x = -Input.get_action_strength("kanan")
		else:									arah_kemudi.x = 0
		
		if Input.is_action_pressed("lompat"):	self.brake = Input.get_action_strength("lompat")
		else:									self.brake = 0

func fokus():
	server.permainan.set("tombol_aksi_2", "kemudikan_sesuatu")
func gunakan(id_pemain):
	if id_pengemudi == id_pemain:					server.gunakan_entitas(name, "_lepas")
	elif id_pengemudi == -1: 						server.gunakan_entitas(name, "_kemudikan")
func hapus(): # ketika tampilan dihapus
	if id_pengemudi != -1 and server.permainan.dunia.get_node("pemain").get_node_or_null(str(id_pengemudi)) != null:
		if id_pengemudi == multiplayer.get_unique_id():
			server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).global_position = posisi_awal
			server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)).rotation = rotasi_awal
		else:
			server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").set_target_node("")
			server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kanan").stop()
			server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").set_target_node("")
			server.permainan.dunia.get_node("pemain/"+str(id_pengemudi)+"/%tangan_kiri").stop()
	queue_free()

func _kemudikan(id):
	# atur pengemudi
	if id == client.id_koneksi:
		server.permainan.dunia.raycast_occlusion_culling.add_exception(self)
		server.permainan.dunia.raycast_occlusion_culling.add_exception(server.permainan.dunia.get_node("pemain/"+str(id)))
		
		server.permainan.dunia.get_node("pemain/"+str(id))._atur_penarget(false)
		server.permainan.dunia.get_node("pemain/"+str(id)+"/pengamat").atur_mode(2)
		await get_tree().create_timer(0.05).timeout		# ini untuk mencegah fungsi !_target di _process()
		server.permainan.set("tombol_aksi_1", "klakson_kendaraan")
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = true
		server.permainan.bantuan_aksi_1 = true
		server.permainan.set("tombol_aksi_2", "berjalan")
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
		server.permainan.bantuan_aksi_2 = true
		
		# atur arah pemain pada mode VR
		if server.permainan.mode_vr and server.permainan.pengamat_vr != null:
			$arah_pengamat_vr.global_rotation = server.permainan.pengamat_vr.global_rotation
			if server.permainan.pengamat_vr.get_node("XRCamera3D").rotation_degrees.y > 0:
				var arah_putar = $arah_pengamat_vr.rotation_degrees.y + absf(server.permainan.pengamat_vr.get_node("XRCamera3D").rotation_degrees.y)
				if $arah_pengamat_vr.rotation_degrees.y < 0:
					$arah_pengamat_vr/arah_putar.rotation_degrees.y = global_rotation.y - arah_putar
				else:
					$arah_pengamat_vr/arah_putar.rotation_degrees.y = -arah_putar
			else:
				var arah_putar = $arah_pengamat_vr.rotation_degrees.y - absf(server.permainan.pengamat_vr.get_node("XRCamera3D").rotation_degrees.y)
				if $arah_pengamat_vr.rotation_degrees.y > 0:
					$arah_pengamat_vr/arah_putar.rotation_degrees.y = global_rotation.y - arah_putar
				else:
					$arah_pengamat_vr/arah_putar.rotation_degrees.y = -arah_putar
		
		# ubah pemroses pada server
		var tmp_kondisi = [["id_proses", id], ["id_pengemudi", id]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	
	# atur id_pengemudi dan id_proses
	id_pengemudi = id
	id_proses = id
func _lepas(id):
	# atur pengemudi
	if id == client.id_koneksi:
		server.permainan.dunia.raycast_occlusion_culling.remove_exception(self)
		server.permainan.dunia.raycast_occlusion_culling.remove_exception(server.permainan.dunia.get_node("pemain/"+str(id)))
		
		server.permainan.dunia.get_node("pemain/"+str(id)).rotation.x = 0
		server.permainan.dunia.get_node("pemain/"+str(id)).rotation.z = 0
		
		server.permainan.dunia.get_node("pemain/"+str(id))._atur_penarget(true)
		server.permainan.dunia.get_node("pemain/"+str(id)+"/pengamat").atur_mode(1)
		server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
		server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		server.permainan.bantuan_aksi_1 = false
		server.permainan.bantuan_aksi_2 = false
		
		# atur ulang arah pemain pada mode VR
		if server.permainan.mode_vr and server.permainan.pengamat_vr != null:
			server.permainan.pengamat_vr.rotation = Vector3.ZERO
			$arah_pengamat_vr/arah_putar.rotation_degrees.y = 0
		
		# reset pemroses pada server
		var tmp_kondisi = [["id_proses", -1], ["id_pengemudi", -1]]
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER: server._sesuaikan_kondisi_entitas(id_proses, name, tmp_kondisi)
		else: server.rpc_id(1, "_sesuaikan_kondisi_entitas", id_proses, name, tmp_kondisi)
	# atur ulang id_pengemudi dan id_proses
	id_pengemudi = -1
	id_proses = -1
func _atur_audio_mesin(delta : float):
	if self.engine_force > 0 and kecepatan_laju > 0:
		if !$AudioAkselerasiMesin.playing:
			$AudioAkselerasiMesin.playing = true
		elif $AudioAkselerasiMesin.volume_db < 1:
			$AudioAkselerasiMesin.volume_db = lerp($AudioAkselerasiMesin.volume_db, 1.0, 1.25 * delta)
		if $AudioPeringatan.playing: $AudioPeringatan.playing = false
		$AudioAkselerasiMesin.pitch_scale = lerpf($AudioAkselerasiMesin.pitch_scale, clamp(kecepatan_laju / 7, 0.7, 2.7), 1.25 * delta)
	elif self.engine_force < 0 and kecepatan_laju < 0:
		if !$AudioAkselerasiMesin.playing:
			$AudioAkselerasiMesin.playing = true
		elif $AudioAkselerasiMesin.volume_db < 0.5:
			$AudioAkselerasiMesin.volume_db = lerp($AudioAkselerasiMesin.volume_db, 0.5, 1.5 * delta)
		$AudioAkselerasiMesin.pitch_scale = clamp(-kecepatan_laju / 5, 0.7, 1.8)
		if !$AudioPeringatan.playing and kecepatan_laju < -1: $AudioPeringatan.playing = true
	else:
		if $AudioAkselerasiMesin.playing:
			if $AudioAkselerasiMesin.volume_db > -10:
				$AudioAkselerasiMesin.volume_db = lerp($AudioAkselerasiMesin.volume_db, -10.0, 0.5 * delta)
				$AudioAkselerasiMesin.pitch_scale = lerp($AudioAkselerasiMesin.pitch_scale, 0.7, 0.5 * delta)
			else:
				$AudioAkselerasiMesin.playing = false
		if $AudioPeringatan.playing: $AudioPeringatan.playing = false
	if abs(kecepatan_laju) > 1:
		if self.brake > 0.5 and rem == false:
			if !$roda_depan/AudioRem.playing: $roda_depan/AudioRem.play()
			if !$roda_belakang_kiri/AudioRem.playing: $roda_belakang_kiri/AudioRem.play()
			if !$roda_belakang_kanan/AudioRem.playing: $roda_belakang_kanan/AudioRem.play()
			rem = true
		elif self.brake < 0.1:
			if $roda_depan/AudioRem.playing: $roda_depan/AudioRem.stop()
			if $roda_belakang_kiri/AudioRem.playing: $roda_belakang_kiri/AudioRem.stop()
			if $roda_belakang_kanan/AudioRem.playing: $roda_belakang_kanan/AudioRem.stop()
			rem = false
		$roda_depan/AudioRem.pitch_scale = clamp(abs(kecepatan_laju/10), 0.6, 1)
		$roda_belakang_kiri/AudioRem.pitch_scale = clamp(abs(kecepatan_laju/10), 0.8, 1.05)
		$roda_belakang_kanan/AudioRem.pitch_scale = clamp(abs(kecepatan_laju/10), 0.8, 1.05)
	elif rem == true:
		if $roda_depan/AudioRem.playing: $roda_depan/AudioRem.stop()
		if $roda_belakang_kiri/AudioRem.playing: $roda_belakang_kiri/AudioRem.stop()
		if $roda_belakang_kanan/AudioRem.playing: $roda_belakang_kanan/AudioRem.stop()
		rem = false
	if (kecepatan_laju - percepatan) < -1:
		if !$AudioTabrak.playing:
			$AudioTabrak.play()
