extends MultiplayerSynchronizer

var kendaraan : VehicleBody3D
var jongkok = false
var lompat 	= false

@export var arah_gerakan := Vector2()
@export var arah_pandangan := 0.0

@onready var karakter : Karakter = get_parent()
@onready var posisi_awal = karakter.global_transform.origin
@onready var rotasi_awal = karakter.rotation

var _hentikan_waktu = false
var _frame_saat_ini = 0 # frame ketika backward ataupun forward
var _tween_posisi_karakter : Tween
var _tween_rotasi_karakter : Tween
var _tween_durasi_timeline : Tween
var _interval_timeline	= 0.05
var _delay_timeline 	= _interval_timeline
var _frame_timeline_sb	= 0 # frame sebelumnya

var _raycast_pemain : RayCast3D
var _target_pemain # kondisi target raycast (true|false)
var objek_target : Node3D
var pos_target : Vector3 # posisi raycast

func atur_pengendali(id):
	set_multiplayer_authority(id)
	var kendali = (get_multiplayer_authority() == multiplayer.get_unique_id())
	#print_debug("get_multiplayer_authority : "+str(get_multiplayer_authority())+" == multiplayer.get_unique_id : "+str(multiplayer.get_unique_id()))
	#print_debug("kendali : "+str(kendali))
	set_process(kendali)
	karakter.set_process(kendali)
	karakter.set_physics_process(kendali)
	karakter._kendalikan(kendali) # gabisa sekedar dipindah ke baris 22
	#print("skibidi bop bop yes yes yes")
	await karakter.atur_model()
	#print("skibidi bop-bop mim mim!")
	karakter.atur_warna() # ini harus cuma bisa di set kalo proses atur_model udah selesai
	# INFO : (8b) mulai permainan
	if kendali:
		Panku.gd_exprenv.register_env("pemain", self)
		Panku.notify(TranslationServer.translate("%spawnpemain"))
		if server.permainan.permukaan != null:
			server.permainan.permukaan.pengamat = karakter.get_node("pengamat").get_node("%pandangan")
		client.permainan.karakter = karakter
		client.permainan._tampilkan_permainan()
	else:
		# INFO : atur layer visibilitas model
		get_node("%GeneralSkeleton/rambut").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/wajah").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/telinga").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/kelopak_mata").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/badan").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/baju").set_layer_mask_value(1, true)

func _ready():
	set_process(false)
	_raycast_pemain = karakter.get_node("pengamat/%target")

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		karakter.arah_pandangan = event.relative
func _process(delta):
	# kendalikan pemain dengan input
	if karakter.kontrol:
		if Input.is_action_pressed("maju"):
			if Input.is_action_pressed("berlari"): arah_gerakan.y = Input.get_action_strength("berlari") * 2
			else: arah_gerakan.y = Input.get_action_strength("maju")
		elif Input.is_action_pressed("mundur"):
			if Input.is_action_pressed("berlari"):arah_gerakan.y = -Input.get_action_strength("berlari") * 2
			else: arah_gerakan.y = -Input.get_action_strength("mundur")
		else:
			if karakter.is_on_floor(): arah_gerakan.y = 0
			else: arah_gerakan.y = lerp(arah_gerakan.y, 0.0, 0.25 * delta)
		
		if Input.is_action_pressed("kiri"):
			if Input.is_action_pressed("berlari"): arah_gerakan.x = Input.get_action_strength("kiri")
			else: arah_gerakan.x = Input.get_action_strength("kiri") / 2
		elif Input.is_action_pressed("kanan"):
			if Input.is_action_pressed("berlari"): arah_gerakan.x = -Input.get_action_strength("kanan")
			else: arah_gerakan.x = -Input.get_action_strength("kanan") / 2
		else: arah_gerakan.x = 0
		
		if Input.is_action_pressed("pandangan_atas"):
			karakter.arah_pandangan.y = -Input.get_action_strength("pandangan_atas")
		elif Input.is_action_pressed("pandangan_bawah"):
			karakter.arah_pandangan.y = Input.get_action_strength("pandangan_bawah")
		
		if Input.is_action_pressed("pandangan_kiri"):
			karakter.arah_pandangan.x = -Input.get_action_strength("pandangan_kiri")
		elif Input.is_action_pressed("pandangan_kanan"):
			karakter.arah_pandangan.x = Input.get_action_strength("pandangan_kanan")
		
		if Input.is_action_pressed("waktu_mundur"):
			if _hentikan_waktu:
				_frame_saat_ini -= 1
				var tmp_frame = server.timeline.keys()
				var tmp_jml_f = tmp_frame.size() - 1 # HACK : harusnya bukan total frame tapi total key
				var tmp_idx_f = tmp_frame[tmp_jml_f + _frame_saat_ini] # kurangi dengan indeks
				if -_frame_saat_ini >= tmp_jml_f - 1: return
				while !server.timeline[tmp_idx_f].has(karakter.id_pemain):
					_frame_saat_ini -= 1 # kurang 1 lagi, artinya mundur 1 frame
					tmp_idx_f = tmp_frame[tmp_jml_f + _frame_saat_ini]
				# setelah indeks ditemukan, terapkan nilai
				var frame_karakter = server.timeline[tmp_idx_f][karakter.id_pemain]
				if frame_karakter["tipe"] != "sinkron": return
				_tween_posisi_karakter = get_tree().create_tween()
				_tween_rotasi_karakter = get_tree().create_tween()
				_tween_durasi_timeline = get_tree().create_tween()
				_tween_posisi_karakter.tween_property(
					karakter,
					"position",
					frame_karakter["posisi"],
					0.25 #(server.timeline["data"]["frame"] - tmp_idx_f) / 1000
				)
				_tween_rotasi_karakter.tween_property(
					karakter,
					"rotation",
					frame_karakter["rotasi"],
					0.25
				)
				_tween_durasi_timeline.tween_property(
					server.permainan.get_node("%timeline/posisi_durasi"),
					"value",
					tmp_idx_f,
					0.25
				)
				_tween_posisi_karakter.play()
				_tween_rotasi_karakter.play()
				_tween_durasi_timeline.play()
				server.permainan.get_node("%timeline/durasi").text = "%s" % [
					server.permainan.detikKeMenit(tmp_idx_f / 1000)
				]
				#print_debug("frame : %s/%s    keyframe : %s    interval : %s" % [-_frame_saat_ini, tmp_jml_f, tmp_idx_f, (server.timeline["data"]["frame"] - tmp_idx_f)/1000])
				#print_debug(frame_karakter)
		
		if Input.is_action_just_pressed("aksi1"):
			if _target_pemain:
				match karakter.peran:
					Permainan.PERAN_KARAKTER.Arsitek:
						# set_cell_item(position: Vector3i, item: int, orientation: int = 0)
						#server.permainan.dunia.get_child(4).get_node("%peta").set_cell_item(
						#	Vector3i(pos_target.x, 0, pos_target.z), 
						#	0, 	# item
						#	0	# orientasi
						#)
						#print_debug(target_pemain)
						
						if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
							server._tambahkan_entitas(
								"res://skena/entitas/placeholder_entitas.tscn",
								Vector3i(pos_target.x, pos_target.y, pos_target.z),
								Vector3.ZERO,
								[
									["modulate", Color(randf(), randf(), randf(), 1)]
								]
							)
						else:
							server.rpc_id(
								1,
								"_tambahkan_entitas",
								"res://skena/entitas/placeholder_entitas.tscn",
								Vector3i(pos_target.x, pos_target.y, pos_target.z),
								Vector3.ZERO,
								[
									["modulate", Color(randf(), randf(), randf(), 1)]
								]
							)
		if Input.is_action_just_pressed("aksi2"):
			if _target_pemain:
				if objek_target.has_method("gunakan"): objek_target.gunakan(multiplayer.get_unique_id())
				elif objek_target.name == "bidang_raycast" and \
				 objek_target.get_parent().has_method("gunakan"):
					objek_target.get_parent().gunakan(multiplayer.get_unique_id())
		
		if Input.is_action_just_pressed("mode_pandangan"): karakter.get_node("pengamat").ubah_mode()
		
		if Input.is_action_just_pressed("jongkok"):
			if karakter.arah.x == 0.0 and karakter.arah.z == 0.0:
				if !jongkok:
					#karakter.get_node("pose").set("parameters/gestur/transition_request", "jongkok")
					var tween = get_tree().create_tween()
					tween.tween_property(karakter.get_node("pose"), "parameters/jongkok/blend_amount", 1, 0.6)
					jongkok = true
					tween.play()
				else:
					#karakter.get_node("pose").set("parameters/gestur/transition_request", "berdiri")
					var tween = get_tree().create_tween()
					tween.tween_property(karakter.get_node("pose"), "parameters/jongkok/blend_amount", 0, 0.6)
					jongkok = false
					tween.play()
		if Input.is_action_just_pressed("hentikan_waktu"):
			if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
				if !_hentikan_waktu:
					karakter.process_mode = Node.PROCESS_MODE_ALWAYS
					karakter.set_physics_process(false)
					#Engine.time_scale = 1.5
					# atur pencahayaan dunia
					server.permainan.dunia.get_node("pencahayaan").environment.set("tonemap_exposure", 2)
					server.permainan.dunia.get_node("pencahayaan").environment.set("tonemap_white", 1.5)
					server.permainan.dunia.process_mode = PROCESS_MODE_DISABLED
					#get_tree().paused = true
					_hentikan_waktu = true
					# update tampilan durasi
					server.permainan.get_node("%timeline/posisi_durasi").max_value 	= server.timeline["data"]["frame"]
					server.permainan.get_node("%timeline/posisi_durasi").value 		= server.timeline["data"]["frame"]
					server.permainan.get_node("%timeline/durasi").text = "%s" % [
						server.permainan.detikKeMenit(server.timeline["data"]["frame"] / 1000)
					]
					# tampilkan tampilan durasi
					server.permainan.get_node("%timeline/animasi").play("tampilkan")
				else:
					_hentikan_waktu = false
					if _tween_posisi_karakter != null:
						_tween_posisi_karakter.stop()
						_tween_rotasi_karakter.stop()
					karakter.process_mode = Node.PROCESS_MODE_INHERIT
					karakter.set_physics_process(true)
					#Engine.time_scale = 1.0
					# sebelum mulai waktu dunia, kalo pemain ke masa lalu, hapus frame setelahnya
					var tmp_frame = server.timeline.keys()
					var tmp_jml_f = tmp_frame.size() - 1
					var tmp_idx_f
					for wkt in -_frame_saat_ini:
						tmp_idx_f = tmp_frame[tmp_jml_f - wkt]
						if server.timeline[tmp_idx_f].has(karakter.id_pemain):
							server.timeline[tmp_idx_f].erase(karakter.id_pemain)
							#print_debug("hapus "+str(tmp_idx_f))
					_frame_saat_ini = 0 # reset posisi pointer frame
					# mulai kembali waktu dunia
					server.permainan.dunia.process_mode = PROCESS_MODE_INHERIT
					server.permainan.dunia.get_node("pencahayaan").environment.set("tonemap_exposure", 0.5)
					server.permainan.dunia.get_node("pencahayaan").environment.set("tonemap_white", 1)
					#get_tree().paused = false
					# sembunyikan tampilan durasi
					server.permainan.get_node("%timeline/animasi").play_backwards("tampilkan")
		if Input.is_action_just_pressed("debug2"):
			if get_viewport().debug_draw == Viewport.DEBUG_DRAW_WIREFRAME:
				get_viewport().debug_draw = Viewport.DEBUG_DRAW_DISABLED
				Panku.notify("modus render normal")
			else:
				get_viewport().debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
				Panku.notify("modus render wireframe")
	
	# atur ulang fungsi melompat ketika berada di floor
	if karakter.is_on_floor() and lompat: lompat = false
	
	# atur ulang posisi kalau terjatuh dari dunia
	if karakter.global_position.y < server.permainan.batas_bawah:
		karakter.global_transform.origin = posisi_awal
		karakter.rotation		 		= rotasi_awal
		Panku.notify("re-spawn")
	
	# Timeline : sinkronkan pemain (rekam)
	if _delay_timeline <= 0.0:
		# perekaman hanya dilakukan di server dan ketika waktu berjalan
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER and server.permainan.dunia.process_mode != PROCESS_MODE_DISABLED:
			if server.timeline.has(server.timeline["data"]["frame"]): pass
			else:
				var frame_sekarang = server.timeline["data"]["frame"]
				server.timeline[frame_sekarang] = {
					karakter.id_pemain: {
						"tipe": 		"sinkron",
						"posisi":		karakter.position,
						"rotasi":		karakter.rotation,
						"skala":		karakter.scale,
						#"kondisi":		
					}
				}
				# kalo data sama dengan frame sebelumnya, hapus kondisi entity dari frame sebelumnya
				if server.timeline[_frame_timeline_sb].has(karakter.id_pemain) and server.timeline[_frame_timeline_sb][karakter.id_pemain] == server.timeline[frame_sekarang][karakter.id_pemain]:
					server.timeline[_frame_timeline_sb].erase(karakter.id_pemain)
				_frame_timeline_sb = frame_sekarang
		# reset delay
		_delay_timeline = _interval_timeline
	elif karakter.id_pemain > 0: _delay_timeline -= delta
func _physics_process(delta):
	# fungsi raycast
	_target_pemain = _raycast_pemain.is_colliding()
	if _target_pemain:
		pos_target = _raycast_pemain.get_collision_point()
		objek_target = _raycast_pemain.get_collider()
		if objek_target.has_method("gunakan") or (objek_target.name == "bidang_raycast" and objek_target.get_parent().has_method("gunakan")):
			server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
		else:
			server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
		match karakter.peran:
			Permainan.PERAN_KARAKTER.Arsitek: # atur posisi pointer
				#var tmp_pos = server.permainan.dunia.get_child(4).get_node("%peta").map_to_local(pos_target)
				#server.permainan.dunia.get_child(4).get_node("%pos_debug").global_position = Vector3(
				#	tmp_pos.x,
				#	server.permainan.dunia.get_child(4).get_node("%peta").global_position.y + 0.5,
				#	tmp_pos.z
				#)
				#server.permainan.dunia.get_child(4).get_node("%pos_debug").visible = true
				pass
	#elif server.permainan.dunia.get_child(4).get_node("%pos_debug").visible: # debug permukaan
	#	server.permainan.dunia.get_child(4).get_node("%pos_debug").visible = false
	elif is_instance_valid(objek_target):
		objek_target = null
		if server.permainan.get_node("kontrol_sentuh/aksi_2").visible:
			server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
	
	# kendalikan pemain dengan input
	if karakter.kontrol:
		if Input.is_action_pressed("lompat"):
			if !lompat:
				if Input.is_action_pressed("berlari") and karakter.arah.z > 1.0:
					if karakter.is_on_floor():
						karakter.arah.y = 180 * delta
						#lompat = true
					elif Input.is_action_pressed("kiri") or Input.is_action_pressed("kanan"): # ini fitur btw >u<
						karakter.arah.y = 200 * delta
						#lompat = true
				elif karakter.is_on_floor():
					# FIXME : melompat
					#karakter.get_node("model/animasi").get_animation("anim/melompat").track_set_key_value(57, 0, true)
					#karakter.get_node("model/animasi").get_animation("anim/melompat").track_set_key_value(57, 1, true)
					#karakter.get_node("model/animasi").get_animation("anim/melompat").track_set_key_value(57, 4, true)
					#karakter.get_node("model/animasi").get_animation("anim/melompat").track_set_key_value(57, 5, true)
					#karakter.get_node("model/animasi").get_animation("anim/melompat").track_set_key_value(58, 0, arah_gerakan)
					#karakter.get_node("pose").set("parameters/melompat/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
					karakter.arah.y = 150 * delta
				lompat = true

# debug
const _HELP_teleportasi = "Teleportasi ke posisi : Vector3"
func teleportasi(posisi_x, posisi_y, posisi_z):
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		karakter.global_position = Vector3(posisi_x, posisi_y, posisi_z)
		if is_instance_valid(kendaraan): kendaraan.global_position = Vector3(posisi_x, posisi_y, posisi_z)
