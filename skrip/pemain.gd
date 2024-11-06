extends MultiplayerSynchronizer

var kendaraan : VehicleBody3D
var jongkok = false
var lompat 	= false

@export var gunakan_frustum_culling : bool = true
@export var gunakan_occlusion_culling : bool = true

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

var _raycast_pemain : RayCast3D
var _raycast_serangan_a_pemain : RayCast3D
var _target_pemain # kondisi target raycast (true|false)
var objek_target : Node3D
var pos_target : Vector3 # posisi raycast

func atur_pengendali(id):
	await karakter.atur_model()
	karakter.atur_warna()
	if not server.mode_replay:
		set_multiplayer_authority(id)
		var kendali = (get_multiplayer_authority() == multiplayer.get_unique_id())
		#print_debug("get_multiplayer_authority : "+str(get_multiplayer_authority())+" == multiplayer.get_unique_id : "+str(multiplayer.get_unique_id()))
		#print_debug("kendali : "+str(kendali))
		set_process(kendali)
		set_physics_process(kendali)
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.CLIENT:
			karakter.set_process(kendali) # jangan atur/disable ini di server karena untuk timeline
		karakter.set_physics_process(kendali)
		karakter._kendalikan(kendali) # gabisa sekedar dipindah ke baris 22
		
		# INFO : (8b) mulai permainan
		if kendali:
			Panku.gd_exprenv.register_env("pemain", self)
			Panku.notify(TranslationServer.translate("%spawnpemain"))
			karakter.get_node("pengamat").atur_mode(1)
			client.permainan.karakter = karakter
			client.permainan._tampilkan_permainan()
	else:
		karakter.set_process(false)
		karakter.set_physics_process(false)
		set_multiplayer_authority(1)

func _enter_tree():
	set_process(false)
	set_physics_process(false)

func _process(delta):
	# kendalikan pemain dengan input
	if karakter.kontrol:
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
		
		if Input.is_action_just_pressed("aksi2"):
			if _target_pemain:
				match karakter.peran:
					Permainan.PERAN_KARAKTER.Arsitek:
						if server.permainan.memasang_objek: server.permainan._tutup_daftar_objek()
						elif objek_target.has_method("gunakan") or objek_target.is_in_group("dapat_diedit"):
							server.edit_objek(objek_target.name, true)
						elif objek_target.name == "bidang_raycast" and \
						 objek_target.get_parent().has_method("gunakan"):
							server.edit_objek(objek_target.get_parent().name, true)
					_:
						if objek_target.has_method("gunakan"): objek_target.gunakan(multiplayer.get_unique_id())
						elif objek_target.name == "bidang_raycast" and \
						 objek_target.get_parent().has_method("gunakan"):
							objek_target.get_parent().gunakan(multiplayer.get_unique_id())
			else:
				match karakter.peran:
					Permainan.PERAN_KARAKTER.Arsitek:
						if server.permainan.memasang_objek: server.permainan._tutup_daftar_objek()
		
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
	

# debug
const _HELP_teleportasi = "Teleportasi ke posisi : Vector3"
func teleportasi(posisi_x, posisi_y, posisi_z):
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		karakter.global_position = Vector3(posisi_x, posisi_y, posisi_z)
		if is_instance_valid(kendaraan): kendaraan.global_position = Vector3(posisi_x, posisi_y, posisi_z)
