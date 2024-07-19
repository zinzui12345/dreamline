extends Control

class_name Permainan

## ChangeLog ##
# 07 Jul 2023 | 1.3.5 - Implementasi LAN Server berbasis Cross-Play
# 04 Agu 2023 | 1.3.5 - Implementasi Timeline
# 09 Agu 2023 | 1.3.5 - Voice Chat telah berhasil di-implementasikan : Metode optimasi yang digunakan adalah metode kompresi ZSTD
# 11 Agu 2023 | 1.3.6 - Penerapan notifikasi PankuConsole dan tampilan durasi timeline
# 14 Agu 2023 | 1.3.6 - Implementasi Terrain : Metode optimasi menggunakan Frustum Culling dan Object Culling
# 15 Agu 2023 | 1.3.6 - Implementasi Vegetasi Terrain : Metode optimasi menggunakan RenderingServer / Low Level Rendering
# 06 Sep 2023 | 1.3.7 - Perubahan animasi karakter dan penerapan Animation Retargeting pada karakter
# 18 Sep 2023 | 1.3.7 - Implementasi shader karakter menggunakan MToon
# 21 Sep 2023 | 1.3.7 - Perbaikan karakter dan penempatan posisi kamera First Person
# 23 Sep 2023 | 1.3.8 - Penambahan entity posisi spawn pemain
# 25 Sep 2023 | 1.3.8 - Penambahan Text Chat
# 09 Okt 2023 | 1.3.8 - Mode kamera kendaraan dan kontrol menggunakan arah pandangan
# 10 Okt 2023 | 1.3.9 - Penambahan senjata Bola salju raksasa
# 12 Okt 2023 | 1.3.9 - Tombol Sentuh Fleksibel
# 14 Okt 2023 | 1.3.9 - Penambahan Mode Edit Objek
# 21 Okt 2023 | 1.4.0 - Mode Edit Objek telah berhasil di-implementasikan
# 31 Okt 2023 | 1.4.0 - Perbaikan kesalahan kontrol sentuh
# 08 Nov 2023 | 1.4.0 - Implementasi Koneksi Publik menggunakan UPnP
# 17 Nov 2023 | 1.4.1 - Implementasi Proyektil
# 27 Nov 2023 | 1.4.1 - Penambahan kemampuan penghindaran npc terhadap musuhnya
# 10 Des 2023 | 1.4.1 - Perbaikan ragdoll karakter
# 19 Des 2023 | 1.4.2 - Tampilan bar nyawa npc_ai
# 04 Jan 2024 | 1.4.2 - Implementasi GPU Instancing pada Vegetasi Terrain
# 14 Jan 2024 | 1.4.2 - Penambahan Editor Kode
# 04 Feb 2024 | 1.4.3 - Penerapan pemutar ulang Timeline
# 14 Apr 2024 | 1.4.3 - Implementasi Object Pooling pada entitas
# 18 Apr 2024 | 1.4.3 - Penambahan Dialog Informasi
# 04 Mei 2024 | 1.4.4 - Implementasi Object Pooling pada objek
# 04 Jun 2024 | 1.4.4 - Penambahan Editor Blok Kode
# 04 Jul 2024 | 1.4.4 - Demo Uji Performa

const versi = "Dreamline v1.4.4 19/07/24 alpha"
const karakter_cewek = preload("res://karakter/rulu/rulu.scn")
const karakter_cowok = preload("res://karakter/reno/reno.scn")

#region properti
var data : Dictionary = {
	"nama":			"",
	"gender": 		"P",
	"alis":			0,
	"garis_mata":	0,
	"mata":			0,
	"warna_mata":	Color("252525"),
	"rambut":		0,
	"warna_rambut":	Color("252525"),
	"baju":			0,
	"warna_baju":	Color("4e3531"),
	"celana":		0,
	"warna_celana":	Color.WHITE,
	"sepatu":		0,
	"warna_sepatu":	Color.WHITE,
	"posisi":		Vector3.ZERO,
	"rotasi":		Vector3.ZERO,
	"sistem":		OS.get_distribution_name(),
	"id_sys":		OS.get_unique_id()
}
var karakter : CharacterBody3D
var dunia : Node3D = null
var map : Node3D = null
var permukaan					# Permukaan (Terrain)
var batas_bawah : int = -4000	# batas area untuk re-spawn
var edit_objek : Node3D			# ref objek yang sedang di-edit
var memasang_objek : bool = false
var pasang_objek : Vector3		# posisi objek yang akan dipasang
var thread := Thread.new()
var koneksi := MODE_KONEKSI.CLIENT
var gunakan_frustum_culling : bool = true
var gunakan_occlusion_culling : bool = true
var jeda : bool = false
var pesan : bool = false		# ketika input pesan ditampilkan
var _posisi_tab_koneksi : StringName = "LAN" # | "Internet"
var _rotasi_tampilan_karakter : Vector3
var _mode_pandangan_sblm_edit_objek : int = 1
var _rotasi_tampilan_objek : Vector3
var _arah_gestur_tampilan_karakter : Vector2
var _arah_gestur_tampilan_objek : Vector2
var _gerakan_gestur_tampilan_objek : Vector2
var _touchpad_disentuh : bool = false
var _arah_sentuhan_touchpad : Vector2
var _timer_kirim_suara := Timer.new()
var _timer_tampilkan_pesan := Timer.new()
var tombol_aksi_1 : StringName = "lempar_sesuatu" :
	set(ikon):
		if ikon != tombol_aksi_1:
			get_node("kontrol_sentuh/aksi_1/tombol_sentuh").set("texture_normal", load("res://ui/tombol/%s.svg" % [ikon]))
			tombol_aksi_1 = ikon
		match ikon:
			"pasang_objek":		$hud/bantuan_input/aksi1/teks.text = "%pasang"
			"gunakan_objek":	$hud/bantuan_input/aksi1/teks.text = "%gunakan"
			"dorong_sesuatu":	$hud/bantuan_input/aksi1/teks.text = "%dorong"
			"lempar_sesuatu":	$hud/bantuan_input/aksi1/teks.text = "%lempar"
var tombol_aksi_2 : StringName = "angkat_sesuatu" :
	set(ikon):
		if ikon != tombol_aksi_2:
			get_node("kontrol_sentuh/aksi_2").set("texture_normal", load("res://ui/tombol/%s.svg" % [ikon]))
			tombol_aksi_2 = ikon
		match ikon:
			"edit_objek":		$hud/bantuan_input/aksi2/teks.text = "%edit"
			"angkat_sesuatu":	$hud/bantuan_input/aksi2/teks.text = "%angkat"
			"jatuhkan_sesuatu":	$hud/bantuan_input/aksi2/teks.text = "%jatuhkan"
			"tanyakan_sesuatu":	$hud/bantuan_input/aksi2/teks.text = "%bantuan"
var tombol_aksi_3 : StringName = "berlari" :
	set(ikon):
		if ikon != tombol_aksi_3:
			get_node("kontrol_sentuh/lari").set("texture_normal", load("res://ui/tombol/%s.svg" % [ikon]))
			tombol_aksi_3 = ikon
var _konfigurasi_awal : Dictionary = {
	"bahasa": 0,
	"mode_layar_penuh": false
}
#endregion

#region enumerasi
enum MODE_KONEKSI {
	SERVER,
	CLIENT
}
enum PERAN_KARAKTER {
	Arsitek,
	Pedagang,
	Penjelajah,
	Nelayan
}
#endregion

#region setup
func _enter_tree() -> void:
	get_tree().get_root().set("min_size", Vector2(980, 600))
	Konfigurasi.muat()
	$setelan.visible = false
	$setelan/panel/gulir/tab_setelan/setelan_umum/pilih_bahasa.disabled = true
	$setelan/panel/gulir/tab_setelan/setelan_umum/pilih_bahasa.selected = Konfigurasi.bahasa
	$setelan/panel/gulir/tab_setelan/setelan_umum/pilih_bahasa.disabled = false
	$setelan/panel/gulir/tab_setelan/setelan_umum/layar_penuh.disabled = true
	$setelan/panel/gulir/tab_setelan/setelan_umum/layar_penuh.button_pressed = Konfigurasi.mode_layar_penuh
	$setelan/panel/gulir/tab_setelan/setelan_umum/layar_penuh.disabled = false
	$setelan/panel/gulir/tab_setelan/setelan_suara/volume_musik.editable = false
	$setelan/panel/gulir/tab_setelan/setelan_suara/volume_musik.value = Konfigurasi.volume_musik_latar
	$setelan/panel/gulir/tab_setelan/setelan_suara/volume_musik.editable = true
	$setelan/panel/gulir/tab_setelan/setelan_performa/jarak_render.editable = false
	$setelan/panel/gulir/tab_setelan/setelan_performa/jarak_render.value = Konfigurasi.jarak_render
	$setelan/panel/gulir/tab_setelan/setelan_performa/jarak_render.editable = true
	$setelan/panel/gulir/tab_setelan/setelan_input/pilih_kontrol_gerak.disabled = true
	$setelan/panel/gulir/tab_setelan/setelan_input/pilih_kontrol_gerak.selected = Konfigurasi.mode_kontrol_gerak
	$setelan/panel/gulir/tab_setelan/setelan_input/pilih_kontrol_gerak.disabled = false
	$setelan/panel/gulir/tab_setelan/setelan_input/sensitivitas_gestur.editable = false
	$setelan/panel/gulir/tab_setelan/setelan_input/sensitivitas_gestur.value = Konfigurasi.sensitivitasPandangan
	$setelan/panel/gulir/tab_setelan/setelan_input/sensitivitas_gestur.editable = true
func _ready() -> void:
	if dunia == null:
		dunia = await load("res://skena/dunia.scn").instantiate()
		get_tree().get_root().call_deferred("add_child", dunia)
		dunia.set_process(false)
	# INFO : (1) muat data konfigurasi atau terapkan konfigurasi default
	if FileAccess.file_exists(Konfigurasi.data_pemain):
		var file : FileAccess = FileAccess.open(Konfigurasi.data_pemain, FileAccess.READ)
		data = file.get_var()
		file.close()
	# Muat data karakter
	# INFO : (2) non-aktifkan proses untuk placeholder karakter
	get_node("%karakter/lulu").set_process(false)
	get_node("%karakter/lulu").set_physics_process(false)
	get_node("%karakter/lulu").model["alis"] 		= data["alis"]
	get_node("%karakter/lulu").model["garis_mata"] 	= data["garis_mata"]
	get_node("%karakter/lulu").model["mata"] 		= data["mata"]
	get_node("%karakter/lulu").warna["mata"] 		= data["warna_mata"]
	get_node("%karakter/lulu").model["rambut"] 		= data["rambut"]
	get_node("%karakter/lulu").warna["rambut"] 		= data["warna_rambut"]
	get_node("%karakter/lulu").model["baju"] 		= data["baju"]
	get_node("%karakter/lulu").warna["baju"] 		= data["warna_baju"]
	get_node("%karakter/lulu").model["celana"] 		= data["celana"]
	get_node("%karakter/lulu").warna["celana"] 		= data["warna_celana"]
	get_node("%karakter/lulu").model["sepatu"] 		= data["sepatu"]
	get_node("%karakter/lulu").warna["sepatu"] 		= data["warna_sepatu"]
	get_node("%karakter/lulu").atur_model()
	get_node("%karakter/lulu").atur_warna()
	get_node("%karakter/reno").set_process(false)
	get_node("%karakter/reno").set_physics_process(false)
	get_node("%karakter/reno").model["alis"] 		= data["alis"]
	get_node("%karakter/reno").model["garis_mata"] 	= data["garis_mata"]
	get_node("%karakter/reno").model["mata"] 		= data["mata"]
	get_node("%karakter/reno").warna["mata"] 		= data["warna_mata"]
	get_node("%karakter/reno").model["rambut"] 		= data["rambut"]
	get_node("%karakter/reno").warna["rambut"] 		= data["warna_rambut"]
	get_node("%karakter/reno").model["baju"] 		= data["baju"]
	get_node("%karakter/reno").warna["baju"] 		= data["warna_baju"]
	get_node("%karakter/reno").model["celana"] 		= data["celana"]
	get_node("%karakter/reno").warna["celana"] 		= data["warna_celana"]
	get_node("%karakter/reno").model["sepatu"] 		= data["sepatu"]
	get_node("%karakter/reno").warna["sepatu"] 		= data["warna_sepatu"]
	get_node("%karakter/reno").atur_model()
	get_node("%karakter/reno").atur_warna()
	match data["gender"]: # di dunia ini cuman ada 2 gender!
		'P': $karakter/panel/tab/tab_personalitas/pilih_gender.select(0); _ketika_mengubah_gender_karakter(0)
		'L': $karakter/panel/tab/tab_personalitas/pilih_gender.select(1); _ketika_mengubah_gender_karakter(1)
	$hud.visible = false
	$mode_bermain.visible = false
	$kontrol_sentuh.visible = false
	$kontrol_sentuh/aksi_2.visible = false
	$hud/daftar_properti_objek/DragPad.visible = false
	
	# setup timer berbicara
	add_child(_timer_kirim_suara)
	_timer_kirim_suara.wait_time = 2.0
	_timer_kirim_suara.connect("timeout", Callable(self, "_kirim_suara"))
	
	# setup timer pesan
	add_child(_timer_tampilkan_pesan)
	_timer_tampilkan_pesan.wait_time = 2.0
	_timer_tampilkan_pesan.connect("timeout", Callable(self, "_sembunyikan_pesan"))
	
	# setup timeline
	server.set_process(false)
	server.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# INFO : (2b) sesuaikan fungsi antarmuka pada smartphone
	if OS.get_distribution_name() == "Android":
		# aktifkan otomatis kontrol sentuh di android
		Konfigurasi.mode_kontrol_sentuh = true
		# non-aktifkan bantuan tombol aksi
		$hud/bantuan_input.visible = false
		# karena resolusi bayangan adalah 1/2, maka set jaraknya juga
		dunia.get_node("matahari").directional_shadow_max_distance /= 2
	
	# setup dialog
	DialogueManager.dialogue_ended.connect(tutup_dialog)
	
	# INFO : (3) tampilkan menu utama
	$latar.tampilkan()
	await get_tree().create_timer(0.15).timeout
	$menu_utama/animasi.play("tampilkan")
	await get_tree().create_timer($menu_utama/animasi.current_animation_length).timeout
	$menu_utama/menu/Panel/buat_server.grab_focus()
	_mainkan_musik_latar()
#endregion

func _process(delta : float) -> void:
	# tampilan karakter di setelan karakter
	if $karakter.visible:
		_rotasi_tampilan_karakter = Vector3(0, _arah_gestur_tampilan_karakter.x, 0) * (Konfigurasi.sensitivitasPandangan * 2) * delta
		if $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y < -360:
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y += 360
		if $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y > 360:
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y -= 360
		if $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y <= -180:
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y += 90 * 4
		if $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y >= 180:
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y -= 90 * 4
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y -= _rotasi_tampilan_karakter.y
		if $karakter/panel/pilih_tab_wajah.button_pressed and _rotasi_tampilan_karakter.y != 0:
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y = clampf(
				$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y,
				-60, 60
			)
	
	# pemutar musik
	if $pemutar_musik.visible:
		$pemutar_musik/posisi_durasi.value = $pemutar_musik/AudioStreamPlayer.get_playback_position()
		$pemutar_musik/durasi.text = "%s/%s" % [
			detikKeMenit($pemutar_musik/posisi_durasi.value), 
			detikKeMenit($pemutar_musik/posisi_durasi.max_value)
		]
	
	# frekuensi mikrofon
	if $hud/frekuensi_mic.visible:
		var idx := AudioServer.get_bus_index("Suara Pemain")
		var effect := AudioServer.get_bus_effect_instance(idx, 1)
		var magnitude : float = effect.get_magnitude_for_frequency_range(1, 11050.0 / 4).length()
		var energy : float = clamp((60 + linear_to_db(magnitude)) / 60, 0, 1)
		$hud/frekuensi_mic/posisi/persentasi.value = energy * 100
	
	# input
	if is_instance_valid(karakter): # ketika dalam permainan
		if Input.is_action_just_pressed("ui_cancel"):
			if pesan: _tampilkan_input_pesan()
			elif $setelan.visible: _sembunyikan_setelan_permainan()
			elif edit_objek != null: server.edit_objek(edit_objek.name, false)
			elif !jeda: _jeda()
			else: _lanjutkan()
		if Input.is_action_pressed("berbicara") and !pesan: _berbicara(true)
		if Input.is_action_just_pressed("daftar_pemain") and (edit_objek == null and !jeda):
			$mode_bermain.visible = false
			$hud/daftar_pemain/animasi.play("tampilkan")
		if Input.is_action_just_pressed("tampilkan_pesan") and !jeda: _tampilkan_input_pesan()
		if Input.is_action_just_pressed("ui_text_completion_accept") and pesan: _kirim_pesan()
		
		if Input.is_action_just_released("berbicara"): _berbicara(false)
		if Input.is_action_just_released("daftar_pemain") and $hud/daftar_pemain/panel.anchor_left > -1:
			$mode_bermain.visible = true
			$hud/daftar_pemain/animasi.play_backwards("tampilkan")
		
		# kontrol rotasi pandangan ketika mengedit objek
		if get_node_or_null("pengamat") != null and !server.mode_replay and !server.mode_uji_performa:
			if $pengamat/kamera/rotasi_vertikal/pandangan.current and $hud/daftar_properti_objek/DragPad.visible:
				_rotasi_tampilan_objek = Vector3(_arah_gestur_tampilan_objek.y, _arah_gestur_tampilan_objek.x, 0) * Konfigurasi.sensitivitasPandangan * delta
				if _arah_gestur_tampilan_objek != _gerakan_gestur_tampilan_objek:
					$pengamat/kamera/rotasi_vertikal.rotation_degrees.x += _rotasi_tampilan_objek.x
					$pengamat/kamera.rotation_degrees.y -= _rotasi_tampilan_objek.y
					_arah_gestur_tampilan_objek = Vector2.ZERO
					_gerakan_gestur_tampilan_objek = _arah_gestur_tampilan_objek
				
				# kontrol zoom pengamat objek
				if Input.is_action_just_pressed("perdekat_pandangan") or Input.is_action_just_pressed("perjauh_pandangan"):
					if _touchpad_disentuh:
						$pengamat/posisi_mata.fungsi_zoom = true
					else:
						$pengamat/posisi_mata.fungsi_zoom = false
	
	if Input.is_action_just_pressed("ui_cancel"): _kembali()
	if Input.is_action_just_pressed("modelayar_penuh"):
		$setelan/panel/gulir/tab_setelan/setelan_umum/layar_penuh.button_pressed = not $setelan/panel/gulir/tab_setelan/setelan_umum/layar_penuh.button_pressed
		Panku.notify("modelayar_penuh : "+str(Konfigurasi.mode_layar_penuh))
	
	# jangan sembunyikan tombol tutup edit objek
	if is_instance_valid(edit_objek) and !$kontrol_sentuh/aksi_2.visible:
		$kontrol_sentuh/aksi_2.visible = true
	
	# timeline
	if %timeline.visible and server.mode_replay and not server.mode_uji_performa:
		var pemutar_animasi : AnimationPlayer = dunia.get_node("alur_waktu")
		if pemutar_animasi.is_playing():
			%timeline/posisi_durasi.value = pemutar_animasi.current_animation_position
			%timeline/durasi.text = "%s/%s" % [
				detikKeMenit(int(pemutar_animasi.current_animation_position)),
				detikKeMenit(int(pemutar_animasi.current_animation_length))
			]
		elif %timeline/mainkan.disabled:
			%timeline/mainkan.disabled = false
	
	# informasi
	var info_mode_koneksi := ""
	match koneksi:
		0: info_mode_koneksi = "server"
		1: info_mode_koneksi = "client"
	if $performa.visible:
		var info_jumlah_sudut := "0"
		var info_jumlah_entitas := 0
		if server.mode_uji_performa and get_node_or_null("pengamat/viewport_utama/viewport") != null:
			info_jumlah_sudut = str($pengamat/viewport_utama/viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME))
		else:
			info_jumlah_sudut = str(get_tree().get_root().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME))
		if is_instance_valid(dunia): info_jumlah_entitas = dunia.get_node("entitas").get_child_count()
		$performa.text = "%s : %s | %s : %s  | %s : %s | VRAM : %s" % [
			TranslationServer.translate("VERTEKS"),
			info_jumlah_sudut,
			TranslationServer.translate("ENTITAS"),
			info_jumlah_entitas,
			TranslationServer.translate("DRAW"),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			String.humanize_size(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED))
		]
	$versi.text = versi+" | "+String.humanize_size(OS.get_static_memory_usage()+OS.get_static_memory_peak_usage())+" | "+str(Engine.get_frames_per_second())+" fps | "+info_mode_koneksi
func _notification(what : int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(karakter): # ketika dalam permainan
			if pesan: _tampilkan_input_pesan()
			elif edit_objek != null: server.edit_objek(edit_objek.name, false)
			elif !jeda: _jeda()
			else: _lanjutkan()
		else: _kembali()
	elif what == NOTIFICATION_WM_ABOUT: _tampilkan_panel_informasi()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST: _keluar()
	elif what == NOTIFICATION_CRASH: putuskan_server(true); print_debug("always fading~")

# core
func uji_performa() -> void:
	server.mode_uji_performa = true
	client.id_koneksi = 1
	koneksi = MODE_KONEKSI.CLIENT
	_mulai_permainan("perf_test", server.map)
func uji_vr() -> void:
	if dunia != null: dunia.queue_free()
	get_tree().change_scene_to_file("res://skena/vr_test.tscn")
func uji_kode() -> void:
	$editor_kode/CodeEdit._jalankan()
func uji_viewport() -> void:
	if dunia != null: dunia.queue_free()
	get_tree().change_scene_to_file("res://tmp/skenario_1.tscn")
func atur_map(nama_map : StringName = "empty") -> String:
	if nama_map == "benchmark": server.map = "benchmark"; uji_performa();				return "memulai uji performa"
	elif ResourceLoader.exists("res://map/%s.tscn" % [nama_map]): server.map = nama_map;return "mengatur map menjadi : "+nama_map
	else: print("file [res://map/%s.tscn] tidak ditemukan" % [nama_map]);				return "map ["+nama_map+"] tidak ditemukan"
func _mulai_permainan(nama_server : String = "localhost", nama_map : StringName = "showcase", posisi := Vector3.ZERO, rotasi := Vector3.ZERO) -> void:
	if $pemutar_musik.visible:
		$pemutar_musik/animasi.play("sembunyikan")
	if $setelan.visible:
		_sembunyikan_setelan_permainan()
	if $buat_server.visible:
		$buat_server/animasi.play("animasi_panel/tutup")
	if $daftar_server.visible:
		client.hentikan_pencarian_server()
		$daftar_server/animasi.play("animasi_panel/tutup")
		_reset_daftar_server_lan()
	if $karakter.visible:
		$karakter/animasi.play("animasi_panel/tutup")
	if $proses_koneksi.visible:
		_sembunyikan_proses_koneksi()
	$menu_utama/animasi.play("sembunyikan")
	await get_tree().create_timer($menu_utama/animasi.current_animation_length).timeout # tunda beberapa milidetik supaya animasi ui smooth
	$proses_memuat/panel_bawah/animasi.play("tampilkan")
	$proses_memuat/panel_bawah/Panel/SpinnerMemuat/AnimationPlayer.play("kuru_kuru")
	$proses_memuat/panel_bawah/Panel/PersenMemuat.text = "0%"
	$proses_memuat/panel_bawah/Panel/ProsesMemuat.value = 0
	$hud/daftar_pemain/panel/informasi/nama_server.text = nama_server
	await get_tree().create_timer($proses_memuat/panel_bawah/animasi.current_animation_length).timeout # tunda beberapa milidetik supaya animasi ui smooth
	# INFO : ambil screenshot placeholder karakter berdasarkan data kemudian simpan sebagai gambar
	get_node("%karakter").visible = true
	var gambar_karakter : Image
	match data["gender"]:
		"L": gambar_karakter = await get_node("%karakter/../tampilan_karakter").dapatkan_tampilan(get_node("%karakter/reno"))
		"P": gambar_karakter = await get_node("%karakter/../tampilan_karakter").dapatkan_tampilan(get_node("%karakter/lulu"))
	if gambar_karakter != null: data["gambar"] = gambar_karakter.data
	get_node("%karakter").visible = false
	_atur_persentase_memuat(1)
	# hapus placeholder karakter untuk menghemat memori
	if $karakter/panel/tampilan/SubViewportContainer/SubViewport.get_node_or_null("pencahayaan_karakter") != null:
		for t_karakter in get_node("%karakter").get_children(): t_karakter.queue_free()
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/lantai/CollisionShape3D.disabled = true
	_atur_persentase_memuat(5)
	await get_tree().create_timer(0.25).timeout # tunda beberapa milidetik supaya animasi ui smooth
	data["posisi"] = posisi
	data["rotasi"] = rotasi
	var tmp_perintah := Callable(self, "_muat_map")
	thread.start(tmp_perintah.bind(nama_map), Thread.PRIORITY_NORMAL)
func _muat_map(file_map : StringName) -> void:
	# INFO : (4) muat map
	map = await load("res://map/%s.tscn" % [file_map]).instantiate()
	map.name = "lingkungan"
	if map.get_node_or_null("posisi_spawn") != null:
		data["posisi"] = map.get_node("posisi_spawn").position
		data["rotasi"] = map.get_node("posisi_spawn").rotation
	if map.get_node_or_null("batas_bawah") != null:
		batas_bawah = map.get_node("batas_bawah").position.y
	call_deferred("_atur_persentase_memuat", 60)
	await get_tree().create_timer(0.5).timeout
	dunia.call_deferred("add_child", map)
	dunia.call_deferred("set_process", true)
	if koneksi == MODE_KONEKSI.SERVER:
		# INFO : (5a) buat server
		server.call_deferred("buat_koneksi")
		if not server.headless:
			# tambah pengamat objek
			var pengamat_objek : Node3D = load("res://skena/pengamat_objek.tscn").instantiate()
			call_deferred("_atur_persentase_memuat", 70)
			call_deferred("add_child", pengamat_objek)
			# tambahkan pemain
			call_deferred("_tambahkan_pemain", 1, data)
			server.pemain["admin"] = {
				"id_client": 1,
				"nama": 	data["nama"],
				"posisi":	data["posisi"],
				"rotasi":	data["rotasi"],
				"model": {
					"gender":		data["gender"],
					"alis":			data["alis"],
					"garis_mata":	data["garis_mata"],
					"mata":			data["mata"],
					"warna_mata":	data["warna_mata"],
					"rambut":		data["rambut"],
					"warna_rambut":	data["warna_rambut"],
					"baju":			data["baju"],
					"warna_baju":	data["warna_baju"],
					"celana":		data["celana"],
					"warna_celana":	data["warna_celana"],
					"sepatu":		data["sepatu"],
					"warna_sepatu":	data["warna_sepatu"]
				},
				"kondisi":		{
					"arah_gerakan": 	Vector3.ZERO,
					"arah_pandangan":	Vector2.ZERO,
					"mode_gestur":		"berdiri",
					"gestur_jongkok": 	0.0,
					"mode_menyerang": 	"a"
				}
			}
			server.pemain_terhubung = 1
			client.id_sesi = "admin"
		else:
			call_deferred("_mulai_server_cli")
	elif koneksi == MODE_KONEKSI.CLIENT:
		if server.mode_replay:
			# INFO : (5b3) muat data replay
			# 04/02/24 :: ubah nilai properti menjadi keyframe animasi
			koneksi = MODE_KONEKSI.SERVER
			var indeks_frame : Array = server.timeline.keys() # berisi indeks seperti nomor frame, dll
			var alur_waktu := AnimationPlayer.new()
			var skenario := Animation.new()
			var pengamat := Camera3D.new()
			var _fungsi_pengamat : GDScript = load("res://skrip/objek/free_look_camera.gd")
			alur_waktu.name = "alur_waktu"
			dunia.call_deferred("add_child", alur_waktu)
			pengamat.name = "pengamat"
			pengamat.current = true
			pengamat.set_script(_fungsi_pengamat)
			call_deferred("add_child", pengamat)
			for frame in indeks_frame:
				if frame is int and server.timeline[frame] != {}:
					var indeks_entitas : Array = server.timeline[frame].keys() # indeks/id entitas misalnya pemain
					var waktu : float = frame * 0.001 # konversi ke satuan milidetik (float)
					for entitas_ in indeks_entitas:
						if server.timeline[frame][entitas_] != {}:
							var data_frame = server.timeline[frame][entitas_]
							if data_frame.tipe == "spawn":
								if data_frame.tipe_objek == "pemain":
									server.timeline.trek[entitas_] = {}
									server.timeline.entitas[entitas_] = "pemain"
									call_deferred("_tambahkan_pemain", entitas_, data_frame.data)
									# matikan visibilitas pemain hingga di-sinkron
									server.timeline.trek[entitas_]["visibilitas"] = skenario.add_track(Animation.TYPE_VALUE)
									skenario.track_set_path(server.timeline.trek[entitas_]["visibilitas"], "pemain/"+str(entitas_)+":visible")
									skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["visibilitas"], Animation.INTERPOLATION_NEAREST)
									skenario.value_track_set_update_mode(server.timeline.trek[entitas_]["visibilitas"], Animation.UPDATE_DISCRETE)
									skenario.track_insert_key(server.timeline.trek[entitas_]["visibilitas"], 0.0, false)
									skenario.track_insert_key(server.timeline.trek[entitas_]["visibilitas"], waktu, true)
									# matikan visibilitas daftar pemain hingga di-sinkron
									server.timeline.trek[entitas_]["visibilitas_"] = skenario.add_track(Animation.TYPE_VALUE)
									skenario.track_set_path(server.timeline.trek[entitas_]["visibilitas_"], "../Dreamline/hud/daftar_pemain/panel/gulir/baris/"+str(entitas_)+":visible")
									skenario.track_insert_key(server.timeline.trek[entitas_]["visibilitas_"], 0.0, false)
									skenario.track_insert_key(server.timeline.trek[entitas_]["visibilitas_"], waktu, true)
								elif data_frame.tipe_objek == "objek":
									server.timeline.trek[entitas_] = {}
									server.timeline.entitas[entitas_] = "objek"
									server.call_deferred("spawn_pool_objek", 1, entitas_, data_frame.sumber, 1, data_frame.posisi, data_frame.rotasi, data_frame.properti)
									# buat track animasi
									server.timeline.trek[entitas_]["visibilitas"] = skenario.add_track(Animation.TYPE_VALUE)
									server.timeline.trek[entitas_]["posisi"] = skenario.add_track(Animation.TYPE_POSITION_3D)
									server.timeline.trek[entitas_]["rotasi"] = skenario.add_track(Animation.TYPE_VALUE)
									# atur track animasi
									skenario.track_set_path(server.timeline.trek[entitas_]["visibilitas"], "objek/"+str(entitas_)+":visible")
									skenario.track_set_path(server.timeline.trek[entitas_]["posisi"], "objek/"+str(entitas_)+":position")
									skenario.track_set_path(server.timeline.trek[entitas_]["rotasi"], "objek/"+str(entitas_)+":rotation")
									skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["visibilitas"], Animation.INTERPOLATION_NEAREST)
									skenario.value_track_set_update_mode(server.timeline.trek[entitas_]["visibilitas"], Animation.UPDATE_DISCRETE)
									skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["posisi"], Animation.INTERPOLATION_NEAREST)
									#skenario.value_track_set_update_mode(server.timeline.trek[entitas_]["posisi"], Animation.UPDATE_DISCRETE)
									skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["rotasi"], Animation.INTERPOLATION_CUBIC)
									skenario.value_track_set_update_mode(server.timeline.trek[entitas_]["rotasi"], Animation.UPDATE_DISCRETE)
									# atur nilai default animasi
									skenario.track_insert_key(server.timeline.trek[entitas_]["visibilitas"], 0.0, false)
									skenario.track_insert_key(server.timeline.trek[entitas_]["visibilitas"], waktu, true)
									skenario.track_insert_key(server.timeline.trek[entitas_]["posisi"], 0.0, data_frame.posisi)
									skenario.track_insert_key(server.timeline.trek[entitas_]["rotasi"], 0.0, data_frame.rotasi)
								elif data_frame.tipe_objek == "entitas":
									server.timeline.trek[entitas_] = {}
									server.timeline.entitas[entitas_] = "entitas"
									server.call_deferred("spawn_pool_entitas", 1, entitas_, data_frame.sumber, 1, data_frame.posisi, data_frame.rotasi, data_frame.properti)
									# buat track animasi
									server.timeline.trek[entitas_]["visibilitas"] = skenario.add_track(Animation.TYPE_VALUE)
									server.timeline.trek[entitas_]["posisi"] = skenario.add_track(Animation.TYPE_POSITION_3D)
									server.timeline.trek[entitas_]["rotasi"] = skenario.add_track(Animation.TYPE_VALUE)
									# atur track animasi
									skenario.track_set_path(server.timeline.trek[entitas_]["visibilitas"], "entitas/"+str(entitas_)+":visible")
									skenario.track_set_path(server.timeline.trek[entitas_]["posisi"], "entitas/"+str(entitas_)+":position")
									skenario.track_set_path(server.timeline.trek[entitas_]["rotasi"], "entitas/"+str(entitas_)+":rotation")
									skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["visibilitas"], Animation.INTERPOLATION_NEAREST)
									skenario.value_track_set_update_mode(server.timeline.trek[entitas_]["visibilitas"], Animation.UPDATE_DISCRETE)
									skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["rotasi"], Animation.INTERPOLATION_CUBIC)
									skenario.value_track_set_update_mode(server.timeline.trek[entitas_]["rotasi"], Animation.UPDATE_DISCRETE)
									# atur nilai default animasi
									skenario.track_insert_key(server.timeline.trek[entitas_]["visibilitas"], 0.0, true)
									skenario.track_insert_key(server.timeline.trek[entitas_]["visibilitas"], waktu, true)
									skenario.track_insert_key(server.timeline.trek[entitas_]["posisi"], 0.0, data_frame.posisi)
									skenario.track_insert_key(server.timeline.trek[entitas_]["rotasi"], 0.0, data_frame.rotasi)
							elif data_frame.tipe == "sinkron":
								if server.timeline.get("entitas") != null and server.timeline.entitas.get(entitas_) != null:
									if server.timeline.entitas[entitas_] == "pemain":
										if server.timeline.trek[entitas_].get("posisi") == null:
											server.timeline.trek[entitas_]["posisi"] = skenario.add_track(Animation.TYPE_POSITION_3D)
											skenario.track_set_path(server.timeline.trek[entitas_]["posisi"], "pemain/"+str(entitas_)+":position")
										if server.timeline.trek[entitas_].get("rotasi") == null:
											server.timeline.trek[entitas_]["rotasi"] = skenario.add_track(Animation.TYPE_VALUE)
											skenario.track_set_path(server.timeline.trek[entitas_]["rotasi"], "pemain/"+str(entitas_)+":rotation_degrees")
											skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["rotasi"], Animation.INTERPOLATION_CUBIC)
											skenario.value_track_set_update_mode(server.timeline.trek[entitas_]["rotasi"], Animation.UPDATE_DISCRETE)
										if server.timeline.trek[entitas_].get("skala") == null:
											server.timeline.trek[entitas_]["skala"] = skenario.add_track(Animation.TYPE_VALUE)
											skenario.track_set_path(server.timeline.trek[entitas_]["skala"], "pemain/"+str(entitas_)+":scale")
										if server.timeline.trek[entitas_].get("arah_gerakan") == null:
											server.timeline.trek[entitas_]["arah_gerakan"] = skenario.add_track(Animation.TYPE_VALUE)
											skenario.track_set_path(server.timeline.trek[entitas_]["arah_gerakan"], "pemain/"+str(entitas_)+"/pose:parameters/arah_gerakan/blend_position")
											skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["arah_gerakan"], Animation.INTERPOLATION_CUBIC)
											skenario.value_track_set_update_mode(server.timeline.trek[entitas_]["arah_gerakan"], Animation.UPDATE_DISCRETE)
										if server.timeline.trek[entitas_].get("arah_y_pandangan") == null:
											server.timeline.trek[entitas_]["arah_y_pandangan"] = skenario.add_track(Animation.TYPE_VALUE)
											skenario.track_set_path(server.timeline.trek[entitas_]["arah_y_pandangan"], "pemain/"+str(entitas_)+"/pose:parameters/arah_y_pandangan/blend_position")
										if server.timeline.trek[entitas_].get("gestur") == null:
											server.timeline.trek[entitas_]["gestur"] = skenario.add_track(Animation.TYPE_VALUE)
											skenario.track_set_path(server.timeline.trek[entitas_]["gestur"], "pemain/"+str(entitas_)+":gestur")
										if server.timeline.trek[entitas_].get("gestur_jongkok") == null:
											server.timeline.trek[entitas_]["gestur_jongkok"] = skenario.add_track(Animation.TYPE_VALUE)
											skenario.track_set_path(server.timeline.trek[entitas_]["gestur_jongkok"], "pemain/"+str(entitas_)+":gestur_jongkok")
										if server.timeline.trek[entitas_].get("lompat") == null:
											server.timeline.trek[entitas_]["lompat?"] = false
											server.timeline.trek[entitas_]["lompat"] = skenario.add_track(Animation.TYPE_VALUE)
											skenario.track_set_path(server.timeline.trek[entitas_]["lompat"], "pemain/"+str(entitas_)+"/pose:parameters/melompat/request")
											skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["lompat"],	Animation.INTERPOLATION_NEAREST)
											skenario.value_track_set_update_mode(server.timeline.trek[entitas_]["lompat"],	Animation.UPDATE_DISCRETE)
											skenario.track_insert_key(server.timeline.trek[entitas_]["lompat"],		0.0,	AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
										if server.timeline.trek[entitas_].get("mode_menyerang_berdiri") == null:
											server.timeline.trek[entitas_]["mode_menyerang_berdiri?"] = ""
											server.timeline.trek[entitas_]["mode_menyerang_berdiri"] = skenario.add_track(Animation.TYPE_VALUE)
											skenario.track_set_path(server.timeline.trek[entitas_]["mode_menyerang_berdiri"], "pemain/"+str(entitas_)+"/pose:parameters/mode_menyerang_berdiri/current_state")
											skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["mode_menyerang_berdiri"], Animation.INTERPOLATION_CUBIC)
											skenario.track_insert_key(server.timeline.trek[entitas_]["mode_menyerang_berdiri"], 0.0, "mendorong")
										if server.timeline.trek[entitas_].get("menyerang_berdiri") == null:
											server.timeline.trek[entitas_]["menyerang_berdiri?"] = false
											server.timeline.trek[entitas_]["menyerang_berdiri"] = skenario.add_track(Animation.TYPE_VALUE)
											skenario.track_set_path(server.timeline.trek[entitas_]["menyerang_berdiri"], "pemain/"+str(entitas_)+"/pose:parameters/menyerang_berdiri/request")
											skenario.track_set_interpolation_type(server.timeline.trek[entitas_]["menyerang_berdiri"],	Animation.INTERPOLATION_NEAREST)
											skenario.value_track_set_update_mode(server.timeline.trek[entitas_]["menyerang_berdiri"],	Animation.UPDATE_DISCRETE)
											skenario.track_insert_key(server.timeline.trek[entitas_]["menyerang_berdiri"],		0.0,	AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
										skenario.track_insert_key(server.timeline.trek[entitas_]["posisi"],				waktu, data_frame.posisi)
										skenario.track_insert_key(server.timeline.trek[entitas_]["rotasi"],				waktu, data_frame.rotasi)
										skenario.track_insert_key(server.timeline.trek[entitas_]["skala"],				waktu, data_frame.skala)
										skenario.track_insert_key(server.timeline.trek[entitas_]["arah_gerakan"],		waktu, data_frame.kondisi.arah_gerakan)
										skenario.track_insert_key(server.timeline.trek[entitas_]["arah_y_pandangan"],	waktu, data_frame.kondisi.arah_y_pandangan)
										skenario.track_insert_key(server.timeline.trek[entitas_]["gestur"],				waktu, data_frame.kondisi.gestur)
										skenario.track_insert_key(server.timeline.trek[entitas_]["gestur_jongkok"],		waktu, data_frame.kondisi.gestur_jongkok)
										if data_frame.kondisi.lompat and not server.timeline.trek[entitas_]["lompat?"]:
											skenario.track_insert_key(server.timeline.trek[entitas_]["lompat"],			waktu, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
											server.timeline.trek[entitas_]["lompat?"] = true
										elif not data_frame.kondisi.lompat and server.timeline.trek[entitas_]["lompat?"]:
											#skenario.track_insert_key(server.timeline.trek[entitas_]["lompat"],			waktu, AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
											server.timeline.trek[entitas_]["lompat?"] = false
										if data_frame.kondisi.menyerang:
											match data_frame.kondisi.gestur:
												"berdiri":
													match data_frame.kondisi.mode_menyerang:
														"a":
															if server.timeline.trek[entitas_]["mode_menyerang_berdiri?"] != "mendorong":
																skenario.track_insert_key(server.timeline.trek[entitas_]["mode_menyerang_berdiri"], waktu, "mendorong")
																server.timeline.trek[entitas_]["mode_menyerang_berdiri?"] = "mendorong"
															if not server.timeline.trek[entitas_]["menyerang_berdiri?"]:
																skenario.track_insert_key(server.timeline.trek[entitas_]["menyerang_berdiri"], waktu, AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
																server.timeline.trek[entitas_]["menyerang_berdiri?"] = true
										elif not data_frame.kondisi.menyerang:
											match data_frame.kondisi.gestur:
												"berdiri":
													match data_frame.kondisi.mode_menyerang:
														"a":
															if server.timeline.trek[entitas_]["menyerang_berdiri?"]:
																#skenario.track_insert_key(server.timeline.trek[entitas_]["menyerang_berdiri"], waktu, AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)
																server.timeline.trek[entitas_]["menyerang_berdiri?"] = false
										skenario.length = waktu
									elif server.timeline.entitas[entitas_] == "objek":
										skenario.track_insert_key(server.timeline.trek[entitas_]["posisi"], waktu, data_frame.posisi)
										skenario.track_insert_key(server.timeline.trek[entitas_]["rotasi"], waktu, data_frame.rotasi)
										skenario.length = waktu
									elif server.timeline.entitas[entitas_] == "entitas":
										skenario.track_insert_key(server.timeline.trek[entitas_]["posisi"], waktu, data_frame.posisi)
										skenario.track_insert_key(server.timeline.trek[entitas_]["rotasi"], waktu, data_frame.rotasi)
										skenario.length = waktu
							elif data_frame.tipe == "hapus":
								# hapus entitas
								skenario.track_insert_key(server.timeline.trek[entitas_]["visibilitas"], waktu, false)
								# jika entitas adalah pemain, matikan visibilitas dari daftar pemain
								if server.timeline.entitas[entitas_] == "pemain": skenario.track_insert_key(server.timeline.trek[entitas_]["visibilitas_"], waktu, false)
			var pustaka_animasi := AnimationLibrary.new()
			pustaka_animasi.add_animation("skenario", skenario)
			alur_waktu.add_animation_library("alur_waktu", pustaka_animasi)
			# $root.dunia.get_node("alur_waktu").play("alur_waktu/skenario")
			ResourceSaver.save(skenario, "res://tmp/uji_animasi.res")
		elif server.mode_uji_performa:
			# INFO : (5b4) tampilkan halaman uji performa
			# 28/06/24 :: demo uji algoritma object culling
			koneksi = MODE_KONEKSI.SERVER
			server.mode_replay = true
			server.set_process(true)
			call_deferred("_tampilkan_permainan")
			var pengamat : Control = load("res://skena/perf_test.tscn").instantiate()
			pengamat.name = "pengamat"
			call_deferred("add_child", pengamat)
		else:
			# tambah pengamat objek
			var pengamat_objek : Node3D = load("res://skena/pengamat_objek.tscn").instantiate()
			call_deferred("_atur_persentase_memuat", 70)
			call_deferred("add_child", pengamat_objek)
			# INFO : (5b1) kirim data pemain ke server
			server.call_deferred("rpc", "_tambahkan_pemain_ke_dunia", client.id_koneksi, client.id_sesi, data)
	thread.call_deferred("wait_to_finish")
func _mulai_server_cli() -> void:
	print(alamat_ip())
	if permukaan != null: permukaan.gunakan_frustum_culling = false
func _tambahkan_pemain(id: int, data_pemain : Dictionary) -> void:
	if is_instance_valid(dunia):
		# tambahkan pemain utama
		if id == client.id_koneksi or server.mode_replay:
			var pemain : Karakter
			match data_pemain["gender"]:
				"L": pemain = karakter_cowok.instantiate()
				"P": pemain = karakter_cewek.instantiate()
			if !is_instance_valid(pemain): print("tidak dapat menambahkan pemain "+str(id)); return
			karakter = pemain
			dunia.pengamat = karakter.get_node("pengamat/%pandangan")
			if permukaan != null: permukaan.pengamat = karakter.get_node("pengamat").get_node("%pandangan")
		
			# INFO : (6) terapkan data pemain ke model pemain
			pemain.id_pemain = id
			pemain.name = str(id)
			pemain.nama 				= data_pemain["nama"]
			pemain.gender 				= data_pemain["gender"]
			pemain.model["alis"] 		= data_pemain["alis"]
			pemain.model["garis_mata"] 	= data_pemain["garis_mata"]
			pemain.model["mata"] 		= data_pemain["mata"]
			pemain.warna["mata"] 		= data_pemain["warna_mata"]
			pemain.model["rambut"] 		= data_pemain["rambut"]
			pemain.warna["rambut"] 		= data_pemain["warna_rambut"]
			pemain.model["baju"] 		= data_pemain["baju"]
			pemain.warna["baju"] 		= data_pemain["warna_baju"]
			pemain.model["celana"] 		= data_pemain["celana"]
			pemain.warna["celana"] 		= data_pemain["warna_celana"]
			pemain.model["sepatu"] 		= data_pemain["sepatu"]
			pemain.warna["sepatu"] 		= data_pemain["warna_sepatu"]
			
			# INFO : (7) tambahkan pemain ke dunia
			dunia.get_node("pemain").add_child(pemain, true)
			
			# terapkan kondisi
			pemain.position = data_pemain["posisi"]
			pemain.rotation = data_pemain["rotasi"]
			pemain.posisi_awal = pemain.global_position
			pemain.rotasi_awal = pemain.rotation
			
			# terapkan tampilan
			pemain.atur_model()
			pemain.atur_warna()
			
			# INFO : (8a) mulai permainan
			_tampilkan_permainan()
			
			# kendalikan karakter
			if not server.mode_replay:
				pemain.set_process(true)
				pemain.set_physics_process(true)
				pemain._atur_kendali(true)
				pemain.get_node("pengamat").atur_mode(1)
				pemain.get_node("pengamat").aktifkan(true)
			else:
				pemain.set_process(false)
				pemain.set_physics_process(false)
		
		# Timeline : spawn pemain
		if koneksi == Permainan.MODE_KONEKSI.SERVER and not server.mode_replay:
			var sumber := ""
			match data_pemain["gender"]:
				"L": sumber = karakter_cowok.resource_path
				"P": sumber = karakter_cewek.resource_path
			if not server.mode_replay:
				if not server.timeline.has(server.timeline["data"]["frame"]):
					server.timeline[server.timeline["data"]["frame"]] = {}
				server.timeline[server.timeline["data"]["frame"]][id] = {
					"tipe": 		"spawn",
					"tipe_objek":	"pemain",
					"sumber": 		sumber,
					"data": 		data_pemain
				}
		
		# INFO : tambah info pemain ke daftar pemain
		_tambah_daftar_pemain(id, {
			"nama"	: data_pemain["nama"],
			"sistem": data_pemain["sistem"],
			"id_sys": data_pemain["id_sys"],
			"gender": data_pemain["gender"],
			"gambar": data_pemain["gambar"]
		})
	else: print("tidak dapat menambahkan pemain sebelum memuat dunia!")
func _berbicara(fungsi : bool) -> void:
	var idx := AudioServer.get_bus_index("Suara Pemain")
	var effect : AudioEffect = AudioServer.get_bus_effect(idx, 0)
	if is_instance_valid(karakter): # hanya berfungsi dalam permainan
		if fungsi and !$suara_pemain.playing:
			_timer_kirim_suara.start() # Mulai timer untuk memicu _kirim_suara setiap 2 detik
			effect.set_recording_active(true)
			$hud/frekuensi_mic/animasi.play("tampilkan")
			$suara_pemain.play()
		elif !fungsi and $suara_pemain.playing:
			_timer_kirim_suara.stop()
			_kirim_suara()
			$hud/frekuensi_mic/animasi.play_backwards("tampilkan")
			await $hud/frekuensi_mic/animasi.animation_finished
			$hud/frekuensi_mic.visible = false
			$suara_pemain.stop()
func _kirim_suara() -> void:
	if $suara_pemain.playing:
		var idx := AudioServer.get_bus_index("Suara Pemain")
		var effect : AudioEffectRecord = AudioServer.get_bus_effect(idx, 0)
		var tmp_suara := effect.get_recording()
		var tmp_ukuran_buffer_suara : int = 0
		if tmp_suara != null:
			# INFO : kompresi data audio
			# BUG : suara menjadi lambat
			# cek : tanpa kompresi = sama saja, artinya bukan diakibatkan oleh kompresi
			# fix : atur pitch_scale suara pada pemain menjadi 2, gatau kenapa apa hasil rekamannya yang lambat atau buffer stream-nya!
			var tmp_data_suara : PackedByteArray = tmp_suara.data
			tmp_ukuran_buffer_suara = tmp_data_suara.size()
			client.data_suara = tmp_data_suara.compress(FileAccess.COMPRESSION_ZSTD)
		effect.set_recording_active(false)
		if client.data_suara.size() == 0: pass
		else: server.rpc("_terima_suara_pemain", client.id_koneksi, client.data_suara, tmp_ukuran_buffer_suara)#; server._terima_suara_pemain(client.id_koneksi, client.data_suara, tmp_ukuran_buffer_suara) # testing
		effect.set_recording_active(true)
		print("kirim suara...")
func _kirim_pesan() -> void:
	if $hud/pesan/layout_input_pesan/input_pesan.text != "":
		if koneksi == MODE_KONEKSI.SERVER: server._terima_pesan_pemain(client.id_sesi, $hud/pesan/layout_input_pesan/input_pesan.text)
		else: server.rpc_id(1, "_terima_pesan_pemain", client.id_sesi, $hud/pesan/layout_input_pesan/input_pesan.text)
		$hud/pesan/layout_input_pesan/input_pesan.text = ""
	$hud/pesan/layout_input_pesan/input_pesan.release_focus()
	$hud/pesan/layout_input_pesan/input_pesan.grab_focus()
func _edit_objek(jalur : String) -> void:
	edit_objek = get_node(jalur)
	karakter._atur_kendali(false)
	karakter.get_node("pengamat").set("kontrol", true)
	if karakter.get_node("pengamat").mode_kontrol != 3:
		_mode_pandangan_sblm_edit_objek = karakter.get_node("pengamat").mode_kontrol
		await get_tree().create_timer(0.1).timeout # kadang eksekusi terlalu cepat sehingga _mode_pandangan_sblm_edit_objek ter-set setelah mode pandangan diubah, alhasil _mode_pandangan_sblm_edit_objek nilainya menjadi 0
		karakter.get_node("pengamat").atur_mode(3)
	karakter._atur_penarget(false)
	$kontrol_sentuh/menu.visible = false
	$kontrol_sentuh/chat.visible = false
	$kontrol_sentuh/mic.visible = false
	$kontrol_sentuh/lari.visible = false
	$kontrol_sentuh/aksi_1.visible = false
	$kontrol_sentuh/lompat.visible = false
	$kontrol_sentuh/jongkok.visible = false
	$kontrol_sentuh/kontrol_gerakan.visible = false
	$kontrol_sentuh/kontrol_pandangan.visible = false
	$hud/daftar_properti_objek/animasi.play("tampilkan")
	$hud/daftar_properti_objek/panel/jalur.text = jalur
	$hud/daftar_properti_objek/panel/pilih_tab_skala.disabled = true
	#$hud/daftar_properti_objek/panel_2/perdekat_objek.min_value = -Konfigurasi.jarak_render
	$hud/daftar_properti_objek/panel_2/perdekat_objek.value = $pengamat.get_node("%pandangan").position.z
	$mode_bermain.visible = false
	_pilih_tab_posisi_objek()
	tombol_aksi_2 = "tutup_panel_objek"
	_touchpad_disentuh = false
	# TODO : dapetin properti kustom objek; mis. warna, kondisi
	for p in $hud/daftar_properti_objek/panel/properti_kustom/baris.get_children(): p.visible = false
	if edit_objek.get("warna_1") != null:
		$hud/daftar_properti_objek/panel/properti_kustom.visible = true
		$hud/daftar_properti_objek/panel/properti_kustom/baris/warna_1.atur_nilai(edit_objek.get("warna_1"))
		$hud/daftar_properti_objek/panel/properti_kustom/baris/warna_1.visible = true
	if edit_objek.get("warna_2") != null:
		$hud/daftar_properti_objek/panel/properti_kustom.visible = true
		$hud/daftar_properti_objek/panel/properti_kustom/baris/warna_2.atur_nilai(edit_objek.get("warna_2"))
		$hud/daftar_properti_objek/panel/properti_kustom/baris/warna_2.visible = true
	if edit_objek.get("skala") != null:
		$hud/daftar_properti_objek/panel/pilih_tab_skala.disabled = false
	# 06/06/24 :: cek apakah objek memiliki node skrip, kemudian aktifkan visibilitas tombol edit skrip
	if edit_objek.get_node_or_null("kode_ubahan") != null and edit_objek.get_node("kode_ubahan") is kode_ubahan:
		$hud/daftar_properti_objek/panel/edit_skrip.visible = true
	# 29/06/24 :: alihkan pengamat
	await get_tree().create_timer(0.1).timeout
	$pengamat.get_node("%pandangan").make_current()
	$pengamat.set_process(true)
	$pengamat.visible = true
func _berhenti_mengedit_objek() -> void:
	$hud/daftar_properti_objek/animasi.play("sembunyikan")
	$hud/daftar_properti_objek/panel/properti_kustom.visible = false
	$hud/daftar_properti_objek/panel/pilih_tab_posisi.release_focus()
	$hud/daftar_properti_objek/panel/pilih_tab_rotasi.release_focus()
	$hud/daftar_properti_objek/panel/pilih_tab_skala.release_focus()
	$hud/daftar_properti_objek/panel/edit_skrip.visible = false
	# kalau mengedit kode, sembunyikan editor
	if $blok_kode.visible: tutup_editor_kode()
	tombol_aksi_2 = "edit_objek"
	$mode_bermain.visible = true
	$kontrol_sentuh/chat.visible = true
	$kontrol_sentuh/mic.visible = true
	$kontrol_sentuh/menu.visible = true
	$kontrol_sentuh/lari.visible = true
	$kontrol_sentuh/lompat.visible = true
	$kontrol_sentuh/jongkok.visible = true
	$kontrol_sentuh/kontrol_gerakan.visible = true
	$kontrol_sentuh/kontrol_pandangan.visible = true
	edit_objek = null
	$pengamat/kamera/rotasi_vertikal/pandangan.clear_current()
	$pengamat.set_process(false)
	$pengamat.visible = false
	karakter._atur_kendali(true)
	karakter.get_node("pengamat").atur_mode(_mode_pandangan_sblm_edit_objek)
	karakter._atur_penarget(true)

# koneksi
func mulai_server(headless : bool = false, nama : StringName = "") -> void:
	koneksi = MODE_KONEKSI.SERVER
	server.headless = headless
	tampilkan_info_koneksi()
	var nama_server : StringName = "localhost"
	if nama != "":
		nama_server = nama
	elif $buat_server/panel/panel_input/nama_server.text != "":
		nama_server = $buat_server/panel/panel_input/nama_server.text
	server.nama = nama_server
	server.jumlah_pemain = $buat_server/panel/panel_input/jumlah_pemain.value
	_mulai_permainan(nama_server, server.map)
func gabung_server() -> void:
	koneksi = MODE_KONEKSI.CLIENT
	var ip : String = $daftar_server/panel/panel_input/input_ip.text
	var port : int = 10567
	if _posisi_tab_koneksi == "LAN":
		if not ip.is_valid_ip_address():
			if ip == "": 	_tampilkan_popup_informasi("%ipkosong",   $daftar_server/panel/panel_input/input_ip)
			else:			_tampilkan_popup_informasi("%iptakvalid", $daftar_server/panel/panel_input/input_ip)
			return
	elif _posisi_tab_koneksi == "Internet":
		if ip == "":
			_tampilkan_popup_informasi("%ipkosong",   $daftar_server/panel/panel_input/input_ip)
			return
		elif ip.get_slice_count(":") == 2:
			# cek pola | 0.tcp.ap.ngrok.io:12089
			var alamat : PackedStringArray = ip.split(":", true, 1)
			ip = alamat[0]
			port = alamat[1].to_int()
			print("mengatur port menjadi {%s}" % [str(port)])
		elif not ip.is_valid_ip_address():
			_tampilkan_popup_informasi("%iptakvalid", $daftar_server/panel/panel_input/input_ip)
			return
	$daftar_server/panel/panel_input/input_ip.grab_focus()
	$proses_koneksi/animasi.play("tampilkan")
	$proses_koneksi/panel/animasi.play("proses")
	$hud/daftar_pemain/panel/informasi/alamat_ip.text = ip
	client.hentikan_pencarian_server()
	client.sambungkan_server(ip, port)
func cari_server() -> void:			client.cari_server()
func cek_koneksi_server() -> void: 	client.cek_koneksi()
func putuskan_server(paksa : bool = false) -> void:
	if is_instance_valid(dunia):
		if koneksi == MODE_KONEKSI.SERVER:
			if server.pemain_terhubung > 1 and !paksa:
				var tmp_f_putuskan := Callable(self, "putuskan_server")
				tmp_f_putuskan = tmp_f_putuskan.bind(true)
				_tampilkan_popup_konfirmasi($menu_utama/menu/Panel/buat_server, tmp_f_putuskan, "%putuskan_server")
				return
			else:
				if server.mode_uji_performa:
					server.set_process(false)
					server.pool_entitas.clear()
					server.pool_objek.clear()
					server.cek_visibilitas_pool_entitas.clear()
					server.cek_visibilitas_pool_objek.clear()
					server.mode_replay = false
					server.mode_uji_performa = false
				elif server.mode_replay:
					dunia.get_node("alur_waktu").queue_free()
					server.mode_replay = false
					%timeline.visible = false
				else:
					server.putuskan()
				$menu_utama/menu/Panel/buat_server.grab_focus()
		elif koneksi == MODE_KONEKSI.CLIENT:
			if edit_objek != null: _berhenti_mengedit_objek()
			client.putuskan_server()
			if $proses_memuat.visible: $proses_memuat/panel_bawah/animasi.play_backwards("tampilkan")
			$menu_utama/menu/Panel/gabung_server.grab_focus()
		
		_sembunyikan_antarmuka_permainan()
		# INFO : (9) tampilkan kembali menu utama
		$menu_jeda/menu/animasi.play("sembunyikan")
		$menu_utama/animasi.play("tampilkan")
		
		get_node("%karakter").add_child(karakter_cewek.instantiate())
		get_node("%karakter/lulu").model["alis"] 		= data["alis"]
		get_node("%karakter/lulu").model["garis_mata"] 	= data["garis_mata"]
		get_node("%karakter/lulu").model["mata"] 		= data["mata"]
		get_node("%karakter/lulu").warna["mata"] 		= data["warna_mata"]
		get_node("%karakter/lulu").model["rambut"] 		= data["rambut"]
		get_node("%karakter/lulu").warna["rambut"] 		= data["warna_rambut"]
		get_node("%karakter/lulu").model["baju"] 		= data["baju"]
		get_node("%karakter/lulu").warna["baju"] 		= data["warna_baju"]
		get_node("%karakter/lulu").model["celana"] 		= data["celana"]
		get_node("%karakter/lulu").warna["celana"] 		= data["warna_celana"]
		get_node("%karakter/lulu").model["sepatu"] 		= data["sepatu"]
		get_node("%karakter/lulu").warna["sepatu"] 		= data["warna_sepatu"]
		get_node("%karakter/lulu").atur_model()
		get_node("%karakter/lulu").atur_warna()
		get_node("%karakter/lulu").set_process(false)
		get_node("%karakter/lulu").set_physics_process(false)
		get_node("%karakter").add_child(karakter_cowok.instantiate())
		get_node("%karakter/reno").model["alis"] 		= data["alis"]
		get_node("%karakter/reno").model["garis_mata"] 	= data["garis_mata"]
		get_node("%karakter/reno").model["mata"] 		= data["mata"]
		get_node("%karakter/reno").warna["mata"] 		= data["warna_mata"]
		get_node("%karakter/reno").model["rambut"] 		= data["rambut"]
		get_node("%karakter/reno").warna["rambut"] 		= data["warna_rambut"]
		get_node("%karakter/reno").model["baju"] 		= data["baju"]
		get_node("%karakter/reno").warna["baju"] 		= data["warna_baju"]
		get_node("%karakter/reno").model["celana"] 		= data["celana"]
		get_node("%karakter/reno").warna["celana"] 		= data["warna_celana"]
		get_node("%karakter/reno").model["sepatu"] 		= data["sepatu"]
		get_node("%karakter/reno").warna["sepatu"] 		= data["warna_sepatu"]
		get_node("%karakter/reno").atur_model()
		get_node("%karakter/reno").atur_warna()
		get_node("%karakter/reno").set_process(false)
		get_node("%karakter/reno").set_physics_process(false)
		match data["gender"]: # di dunia ini cuman ada 2 gender!
			'P': $karakter/panel/tab/tab_personalitas/pilih_gender.select(0); _ketika_mengubah_gender_karakter(0)
			'L': $karakter/panel/tab/tab_personalitas/pilih_gender.select(1); _ketika_mengubah_gender_karakter(1)
		
		koneksi = MODE_KONEKSI.CLIENT
		karakter = null
		dunia.set_process(false)
		dunia.hapus_map()
		dunia.hapus_instance_pemain()
		
		# hapus daftar pemain
		for d_pemain in $hud/daftar_pemain/panel/gulir/baris.get_children(): d_pemain.queue_free()
		
		# hapus pengamat objek
		if get_node_or_null("pengamat") != null:
			$pengamat.queue_free()
		
		$latar.tampilkan()
		_mainkan_musik_latar()
func alamat_ip() -> String:
	var informasi : String = "IP : %s" % [str(server.ip_publik)]
	return informasi

# kontrol
func _ketika_mulai_mengontrol_arah_pandangan() -> void: _touchpad_disentuh = true
func _ketika_mengontrol_arah_pandangan(arah : Vector2, _touchpad : Node) -> void:
	if is_instance_valid(karakter) and !jeda: # ketika dalam permainan
		if _touchpad_disentuh:
			if _arah_sentuhan_touchpad.x == 0:
				karakter._input_arah_pandangan.x = 0
				_arah_gestur_tampilan_objek.x = 0
				_arah_sentuhan_touchpad.x = arah.x
			else:
				karakter._input_arah_pandangan.x = arah.x - _arah_sentuhan_touchpad.x
				_arah_gestur_tampilan_objek.x = arah.x - _arah_sentuhan_touchpad.x
				_arah_sentuhan_touchpad.x = arah.x
			
			if _arah_sentuhan_touchpad.y == 0:
				karakter._input_arah_pandangan.y = 0
				_arah_gestur_tampilan_objek.y = 0
				_arah_sentuhan_touchpad.y = arah.y
			else:
				karakter._input_arah_pandangan.y = arah.y - _arah_sentuhan_touchpad.y
				_arah_gestur_tampilan_objek.y = arah.y - _arah_sentuhan_touchpad.y
				_arah_sentuhan_touchpad.y = arah.y
			
			karakter._input_arah_pandangan.x =  karakter._input_arah_pandangan.x * 100
			karakter._input_arah_pandangan.x = ceil(karakter._input_arah_pandangan.x)
			karakter._input_arah_pandangan.y = -karakter._input_arah_pandangan.y * 100
			karakter._input_arah_pandangan.y = ceil(karakter._input_arah_pandangan.y)
			_arah_gestur_tampilan_objek.x =  _arah_gestur_tampilan_objek.x * 50
			_arah_gestur_tampilan_objek.x = ceil(_arah_gestur_tampilan_objek.x)
			_arah_gestur_tampilan_objek.y = -_arah_gestur_tampilan_objek.y * 50
			_arah_gestur_tampilan_objek.y = ceil(_arah_gestur_tampilan_objek.y)
func _ketika_berhenti_mengontrol_arah_pandangan() -> void:
	_touchpad_disentuh = false
	if is_instance_valid(karakter): # ketika dalam permainan
		_arah_sentuhan_touchpad = Vector2.ZERO
		karakter._input_arah_pandangan = Vector2.ZERO
		_arah_gestur_tampilan_objek = Vector2.ZERO
func _ketika_mengontrol_arah_gerak(arah : Vector2, _analog : Node) -> void:
	if is_instance_valid(karakter): # ketika dalam permainan
		if arah.y > 0.1 and arah.y <= 1.0:
			#maju
			Input.action_press("maju")
		elif arah.y < -0.1 and arah.y >= -1.0:
			#mundur
			Input.action_press("mundur")
		else:
			Input.action_release("maju")
			Input.action_release("mundur")
		
		if arah.x > 0.1 and arah.x <= 1.0:
			Input.action_press("kanan")
		elif arah.x < -0.1 and arah.x >= -1.0:
			Input.action_press("kiri")
		else:
			Input.action_release("kiri")
			Input.action_release("kanan")
func _ketika_mulai_melompat() -> void:		Input.action_press("lompat")
func _ketika_berhenti_melompat() -> void:	Input.action_release("lompat")
func _aksi_1_tekan() -> void: 				Input.action_press("aksi1_sentuh")
func _aksi_1_lepas() -> void: 				Input.action_release("aksi1_sentuh");	$kontrol_sentuh/aksi_1.release_focus()
func _aksi_2_tekan() -> void: 				Input.action_press("aksi2")
func _aksi_2_lepas() -> void: 				Input.action_release("aksi2");			$kontrol_sentuh/aksi_2.release_focus()
func _ketika_mulai_berlari() -> void:		Input.action_press("berlari")
func _ketika_berhenti_berlari() -> void:	Input.action_release("berlari")
func _tombol_jongkok_tekan() -> void:		Input.action_press("jongkok")
func _tombol_jongkok_lepas() -> void:		Input.action_release("jongkok");		$kontrol_sentuh/jongkok.release_focus()
func _mainkan_replay() -> void:
	if server.mode_replay and not server.mode_uji_performa:
		var pemutar_animasi : AnimationPlayer = dunia.get_node("alur_waktu")
		pemutar_animasi.play("alur_waktu/skenario")
		$hud/timeline/posisi_durasi.max_value = pemutar_animasi.current_animation_length
		$hud/timeline/posisi_durasi.value = pemutar_animasi.current_animation_position
		$hud/timeline/mainkan.disabled = true

# UI
func _atur_persentase_memuat(nilai : int) -> void:
	$proses_memuat/panel_bawah/Panel/ProsesMemuat/animasi.get_animation("proses").track_set_key_value(0, 1, nilai)
	$proses_memuat/panel_bawah/Panel/ProsesMemuat/animasi.play("proses")
	$proses_memuat/panel_bawah/Panel/PersenMemuat.text = str(nilai)+"%"
func _tampilkan_permainan() -> void:
	$proses_memuat/panel_bawah/animasi.play_backwards("tampilkan")
	$latar.sembunyikan()
	_hentikan_musik_latar()
	$hud/kompas.visible = true
	$hud/kompas.parent = karakter
	$hud/kompas.set_physics_process(true)
	$mode_bermain.visible = true
	$mode_bermain/main.button_pressed = true
	$mode_bermain/edit.button_pressed = false
	$hud.visible = true
	$kontrol_sentuh.visible = Konfigurasi.mode_kontrol_sentuh
	$kontrol_sentuh/chat.visible = true
	$daftar_objek/tutup/TouchScreenButton.visible = Konfigurasi.mode_kontrol_sentuh
func _sembunyikan_antarmuka_permainan() -> void:
	$hud/bantuan_input/aksi1.visible = false
	$hud/bantuan_input/aksi2.visible = false
	$hud/kompas.set_physics_process(false)
	$hud/kompas.parent = null
	$hud.visible = false
	$mode_bermain.visible = false
	$kontrol_sentuh.visible = false
	$kontrol_sentuh/menu.visible = true
	$daftar_objek/tutup/TouchScreenButton.visible = false
	if $daftar_objek/Panel.anchor_top < 1: $daftar_objek/animasi.play("sembunyikan")
	if $dialog.get_node_or_null("ExampleBalloon") != null: $dialog.get_node("ExampleBalloon").queue_free()
	jeda = false
func _tampilkan_pemutar_musik() -> void:
	if $pemutar_musik.visible: $pemutar_musik/animasi.play("sembunyikan")
	else: $pemutar_musik/animasi.play("tampilkan")
func _tampilkan_konfigurasi_server() -> void:
	if $buat_server.visible:
		_sembunyikan_konfigurasi_server()
	else:
		if $pemutar_musik.visible:	$pemutar_musik/animasi.play("sembunyikan")
		if $daftar_server.visible:
			$daftar_server/animasi.play("tampilkan_buat_server")
		elif $karakter.visible:
			$karakter/animasi.play("tampilkan_buat_server")
		else:
			$buat_server/animasi.play("animasi_panel/tampilkan")
		$buat_server/panel/batal.grab_focus()
func _tambah_jumlah_pemain_server() -> void:	$buat_server/panel/panel_input/jumlah_pemain.value += $buat_server/panel/panel_input/jumlah_pemain.step
func _kurang_jumlah_pemain_server() -> void:	$buat_server/panel/panel_input/jumlah_pemain.value -= $buat_server/panel/panel_input/jumlah_pemain.step
func _sembunyikan_konfigurasi_server() -> void:
	$buat_server/animasi.play("animasi_panel/sembunyikan")
	await get_tree().create_timer($buat_server/animasi.current_animation_length).timeout
	$menu_utama/menu/Panel/buat_server.grab_focus()
func _tampilkan_daftar_server() -> void:
	if $daftar_server.visible: _sembunyikan_daftar_server()
	else:
		if $pemutar_musik.visible: $pemutar_musik/animasi.play("sembunyikan")
		client.cari_server()
		if $buat_server.visible:
			$buat_server/animasi.play("tampilkan_daftar_server")
			await get_tree().create_timer($buat_server/animasi.current_animation_length).timeout
		elif $karakter.visible:
			$karakter/animasi.play("tampilkan_server")
			AudioServer.set_bus_effect_enabled(1, 2, false)
			await get_tree().create_timer($karakter/animasi.current_animation_length).timeout
		else:
			$daftar_server/animasi.play("animasi_panel/tampilkan")
			await get_tree().create_timer($daftar_server/animasi.current_animation_length).timeout
		$daftar_server/panel/panel_input/batal.grab_focus()
func _sembunyikan_daftar_server() -> void:
	client.hentikan_pencarian_server()
	_reset_daftar_server_lan()
	$daftar_server/animasi.play("animasi_panel/sembunyikan")
	await get_tree().create_timer($daftar_server/animasi.current_animation_length).timeout
	$menu_utama/menu/Panel/gabung_server.grab_focus()
func _tambah_server_lan(ip : String, sys : String, nama : StringName, nama_map : StringName, jml_pemain : int, max_pemain : int) -> void:
	var server_lan : Control = load("res://ui/server.tscn").instantiate()
	server_lan.name = ip.replace('.', '_');
	server_lan.atur(ip, sys, nama, nama_map, jml_pemain, max_pemain)
	server_lan.button_group = client.pilih_server
	$daftar_server/panel/daftar_lan/layout.add_child(server_lan)
func _pilih_server_lan(ip : String) -> void:
	$daftar_server/panel/panel_input/input_ip.text = ip
	$daftar_server/panel/panel_input/sambungkan.grab_focus()
func _hapus_server_lan(ip : String) -> void:
	$daftar_server/panel/daftar_lan/layout.get_node(ip.replace('.', '_')).queue_free()
func _reset_daftar_server_lan() -> void:
	var jumlah_koneksi_lan := $daftar_server/panel/daftar_lan/layout.get_child_count()
	for k : int in jumlah_koneksi_lan:
		$daftar_server/panel/daftar_lan/layout.get_child(jumlah_koneksi_lan - (k + 1)).queue_free()
func _pilih_tab_server_lan() -> void:
	if _posisi_tab_koneksi != "LAN":
		$daftar_server/panel/internet.button_pressed = false
		$daftar_server/panel/animasi_tab.play("lan")
		_posisi_tab_koneksi = "LAN"
func _pilih_tab_server_internet() -> void:
	if _posisi_tab_koneksi != "Internet":
		$daftar_server/panel/lan.button_pressed = false
		$daftar_server/panel/animasi_tab.play("internet")
		_posisi_tab_koneksi = "Internet"
func _sembunyikan_proses_koneksi() -> void:
	$proses_koneksi/animasi.play("sembunyikan")
	$proses_koneksi/panel/animasi.stop()
func _tampilkan_setelan_karakter() -> void:
	if $karakter.visible: _sembunyikan_setelan_karakter()
	else:
		if $pemutar_musik.visible: $pemutar_musik/animasi.play("sembunyikan")
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/lantai/CollisionShape3D.disabled = false
		if $karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter.visible == false:
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter.visible = true
			# sesuaikan pilihan dengan data
			$karakter/panel/tab/tab_personalitas/input_nama.set("text", data["nama"])
			match data["gender"]: # INFO : aktifkan visibilitas placeholder karakter berdasarkan data
				"P": get_node("%karakter/lulu").visible = true; $karakter/panel/tab/tab_personalitas/pilih_gender.selected = 0
				"L": get_node("%karakter/reno").visible = true; $karakter/panel/tab/tab_personalitas/pilih_gender.selected = 1
			$karakter/panel/tab/tab_wajah/ScrollContainer/Control/pilih_alis.selected = data["alis"]
			$karakter/panel/tab/tab_wajah/ScrollContainer/Control/pilih_bulu_mata.selected = data["garis_mata"]
			$karakter/panel/tab/tab_wajah/ScrollContainer/Control/pilih_bola_mata.selected = data["mata"]
			$karakter/panel/tab/tab_wajah/ScrollContainer/Control/pemilih_warna.atur_penyesuaian_warna(data["warna_mata"])
			$karakter/panel/tab/tab_rambut/pilih_rambut.selected = data["rambut"]
			$karakter/panel/tab/tab_rambut/pemilih_warna.atur_penyesuaian_warna(data["warna_rambut"])
			$karakter/panel/tab/tab_baju/pilih_baju.selected = data["baju"]
			$karakter/panel/tab/tab_baju/pemilih_warna.atur_penyesuaian_warna(data["warna_baju"])
			$karakter/panel/tab/tab_celana/pilih_celana.selected = data["celana"]
			$karakter/panel/tab/tab_celana/pemilih_warna.atur_penyesuaian_warna(data["warna_celana"])
			$karakter/panel/tab/tab_sepatu/pilih_sepatu.selected = data["sepatu"]
			$karakter/panel/tab/tab_sepatu/pemilih_warna.atur_penyesuaian_warna(data["warna_sepatu"])
		if $buat_server.visible:
			$buat_server/animasi.play("tampilkan_karakter")
		elif $daftar_server.visible:
			$daftar_server/animasi.play("tampilkan_karakter")
			client.hentikan_pencarian_server()
			_reset_daftar_server_lan()
		else: $karakter/animasi.play("tampilkan")
		$karakter/panel/batal.grab_focus()
		AudioServer.set_bus_effect_enabled(1, 2, true)
func _sembunyikan_setelan_karakter() -> void:
	AudioServer.set_bus_effect_enabled(1, 2, false)
	_pilih_tab_personalitas_karakter()
	$karakter/animasi.play("animasi_panel/sembunyikan")
	$menu_utama/menu/Panel/karakter.grab_focus()
func _ketika_ukuran_tampilan_karakter_diubah() -> void:
	$karakter/panel/tampilan/SubViewportContainer/SubViewport.size = $karakter/panel/tampilan.size
func _ketika_mengubah_arah_tampilan_karakter(arah : Vector2, _touchpad : Node) -> void:
	_arah_gestur_tampilan_karakter = arah
func _reset_pilihan_tab_karakter() -> void:
	$karakter/panel/pilih_tab_personalitas.button_pressed = false
	$karakter/panel/pilih_tab_wajah.button_pressed = false
	$karakter/panel/pilih_tab_rambut.button_pressed = false
	$karakter/panel/pilih_tab_baju.button_pressed = false
	$karakter/panel/pilih_tab_celana.button_pressed = false
	$karakter/panel/pilih_tab_sepatu.button_pressed = false
func _pilih_tab_personalitas_karakter() -> void:
	_reset_pilihan_tab_karakter()
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_badan").track_set_key_value(
		0,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.position.y
	)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_badan").track_set_key_value(
		1,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/kamera.size
	)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.play("fokus_badan")
	$karakter/panel/tab.current_tab = 0
	$karakter/panel/pilih_tab_personalitas.button_pressed = true
func _pilih_tab_wajah_karakter() -> void:
	_reset_pilihan_tab_karakter()
	$karakter/panel/tab.current_tab = 1
	$karakter/panel/pilih_tab_wajah.button_pressed = true
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_wajah").track_set_key_value(
		0,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.position.y
	)
	match data["gender"]:
		"P":
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_wajah").track_set_key_value(
				0,
				1,
				0.5
			)
		"L":
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_wajah").track_set_key_value(
				0,
				1,
				0.635
			)
		# note : posisi tinggi cowok = 127% tinggi cewek / posisi tinggi cowok = posisi tinggi cewek * 1.27
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_wajah").track_set_key_value(
		1,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/kamera.size
	)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.play("fokus_wajah")
	# tween putaran pengamat ke <= 60
	if $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y > 60:
		var tween_arah_pengamat : Tween = get_tree().create_tween()
		tween_arah_pengamat.tween_property(
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat,
			"rotation_degrees",
			Vector3(0, 40, 0),
			0.5
		)
		tween_arah_pengamat.play()
	elif $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y < -60:
		var tween_arah_pengamat : Tween = get_tree().create_tween()
		tween_arah_pengamat.tween_property(
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat,
			"rotation_degrees",
			Vector3(0, -40, 0),
			0.5
		)
		tween_arah_pengamat.play()
func _pilih_tab_rambut_karakter() -> void:
	_reset_pilihan_tab_karakter()
	$karakter/panel/tab.current_tab = 2
	$karakter/panel/pilih_tab_rambut.button_pressed = true
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_rambut").track_set_key_value(
		0,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.position.y
	)
	match data["gender"]:
		"P":
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_rambut").track_set_key_value(
				0,
				1,
				0.59
			)
		"L":
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_rambut").track_set_key_value(
				0,
				1,
				0.7493
			)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_rambut").track_set_key_value(
		1,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/kamera.size
	)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.play("fokus_rambut")
func _pilih_tab_baju_karakter() -> void:
	_reset_pilihan_tab_karakter()
	$karakter/panel/tab.current_tab = 3
	$karakter/panel/pilih_tab_baju.button_pressed = true
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_baju").track_set_key_value(
		0,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.position.y
	)
	match data["gender"]:
		"P":
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_baju").track_set_key_value(
				0,
				1,
				-0.005
			)
		"L":
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_baju").track_set_key_value(
				0,
				1,
				0.25
			)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_baju").track_set_key_value(
		1,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/kamera.size
	)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.play("fokus_baju")
func _pilih_tab_celana_karakter() -> void:
	_reset_pilihan_tab_karakter()
	$karakter/panel/tab.current_tab = 4
	$karakter/panel/pilih_tab_celana.button_pressed = true
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_celana").track_set_key_value(
		0,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.position.y
	)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_celana").track_set_key_value(
		1,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/kamera.size
	)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.play("fokus_celana")
func _pilih_tab_sepatu_karakter() -> void:
	_reset_pilihan_tab_karakter()
	$karakter/panel/tab.current_tab = 5
	$karakter/panel/pilih_tab_sepatu.button_pressed = true
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_sepatu").track_set_key_value(
		0,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.position.y
	)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.get_animation("fokus_sepatu").track_set_key_value(
		1,
		0,
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/kamera.size
	)
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat/animasi.play("fokus_sepatu")
func pilih_mode_bermain() -> void:
	if is_instance_valid(karakter) and !jeda:
		$hud/kompas.visible = true
		$mode_bermain/main.button_pressed = true
		$mode_bermain/edit.button_pressed = false
		karakter.peran = Permainan.PERAN_KARAKTER.Penjelajah
		Panku.notify("mode bermain")
		$mode_bermain/main.release_focus()
	if server.mode_replay and not server.mode_uji_performa:
		%timeline/animasi.play_backwards("tampilkan")
func pilih_mode_edit() -> void:
	if is_instance_valid(karakter) and !jeda:
		$hud/kompas.visible = false
		$mode_bermain/main.button_pressed = false
		$mode_bermain/edit.button_pressed = true
		karakter.peran = Permainan.PERAN_KARAKTER.Arsitek
		Panku.notify("mode edit")
		$mode_bermain/edit.release_focus()
	if server.mode_replay and not server.mode_uji_performa:
		%timeline/animasi.play("tampilkan")
		%timeline/durasi.text = "00:00/00:00"
func _pilih_tab_posisi_objek() -> void: 
	$hud/daftar_properti_objek/panel/pilih_tab_posisi.button_pressed = true
	$hud/daftar_properti_objek/panel/pilih_tab_rotasi.button_pressed = false
	$hud/daftar_properti_objek/panel/pilih_tab_skala.button_pressed = false
	$hud/daftar_properti_objek/panel/translasi_x.release_focus()
	$hud/daftar_properti_objek/panel/translasi_x.editable = false
	$hud/daftar_properti_objek/panel/translasi_y.release_focus()
	$hud/daftar_properti_objek/panel/translasi_y.editable = false
	$hud/daftar_properti_objek/panel/translasi_z.release_focus()
	$hud/daftar_properti_objek/panel/translasi_z.editable = false
	if edit_objek != null:
		await get_tree().create_timer(0.05).timeout
		$hud/daftar_properti_objek/panel/translasi_x.min_value = -2147483648
		$hud/daftar_properti_objek/panel/translasi_x.max_value = 2147483647
		$hud/daftar_properti_objek/panel/translasi_x.value = edit_objek.global_transform.origin.x
		$hud/daftar_properti_objek/panel/translasi_y.min_value = -2147483648
		$hud/daftar_properti_objek/panel/translasi_y.max_value = 2147483647
		$hud/daftar_properti_objek/panel/translasi_y.value = edit_objek.global_transform.origin.y
		$hud/daftar_properti_objek/panel/translasi_z.min_value = -2147483648
		$hud/daftar_properti_objek/panel/translasi_z.max_value = 2147483647
		$hud/daftar_properti_objek/panel/translasi_z.value = edit_objek.global_transform.origin.z
		$hud/daftar_properti_objek/panel/translasi_x.editable = true
		$hud/daftar_properti_objek/panel/translasi_y.editable = true
		$hud/daftar_properti_objek/panel/translasi_z.editable = true
func _pilih_tab_rotasi_objek() -> void:
	$hud/daftar_properti_objek/panel/pilih_tab_posisi.button_pressed = false
	$hud/daftar_properti_objek/panel/pilih_tab_rotasi.button_pressed = true
	$hud/daftar_properti_objek/panel/pilih_tab_skala.button_pressed = false
	$hud/daftar_properti_objek/panel/translasi_x.release_focus()
	$hud/daftar_properti_objek/panel/translasi_y.release_focus()
	$hud/daftar_properti_objek/panel/translasi_z.release_focus()
	$hud/daftar_properti_objek/panel/translasi_x.editable = false
	$hud/daftar_properti_objek/panel/translasi_y.editable = false
	$hud/daftar_properti_objek/panel/translasi_z.editable = false
	if edit_objek != null:
		await get_tree().create_timer(0.05).timeout
		$hud/daftar_properti_objek/panel/translasi_x.min_value = -359
		$hud/daftar_properti_objek/panel/translasi_x.max_value = 359
		$hud/daftar_properti_objek/panel/translasi_x.value = edit_objek.rotation_degrees.x
		$hud/daftar_properti_objek/panel/translasi_y.min_value = -359
		$hud/daftar_properti_objek/panel/translasi_y.max_value = 359
		$hud/daftar_properti_objek/panel/translasi_y.value = edit_objek.rotation_degrees.y
		$hud/daftar_properti_objek/panel/translasi_z.min_value = -359
		$hud/daftar_properti_objek/panel/translasi_z.max_value = 359
		$hud/daftar_properti_objek/panel/translasi_z.value = edit_objek.rotation_degrees.z
		$hud/daftar_properti_objek/panel/translasi_x.editable = true
		$hud/daftar_properti_objek/panel/translasi_y.editable = true
		$hud/daftar_properti_objek/panel/translasi_z.editable = true
func _pilih_tab_skala_objek() -> void:
	$hud/daftar_properti_objek/panel/pilih_tab_posisi.button_pressed = false
	$hud/daftar_properti_objek/panel/pilih_tab_rotasi.button_pressed = false
	$hud/daftar_properti_objek/panel/pilih_tab_skala.button_pressed = true
	$hud/daftar_properti_objek/panel/translasi_x.release_focus()
	$hud/daftar_properti_objek/panel/translasi_y.release_focus()
	$hud/daftar_properti_objek/panel/translasi_z.release_focus()
	$hud/daftar_properti_objek/panel/translasi_x.editable = false
	$hud/daftar_properti_objek/panel/translasi_y.editable = false
	$hud/daftar_properti_objek/panel/translasi_z.editable = false
	if edit_objek != null:
		await get_tree().create_timer(0.05).timeout
		$hud/daftar_properti_objek/panel/translasi_x.min_value = 0.1
		$hud/daftar_properti_objek/panel/translasi_x.max_value = 100
		$hud/daftar_properti_objek/panel/translasi_x.value = edit_objek.skala.x
		$hud/daftar_properti_objek/panel/translasi_y.min_value = 0.1
		$hud/daftar_properti_objek/panel/translasi_y.max_value = 100
		$hud/daftar_properti_objek/panel/translasi_y.value = edit_objek.skala.y
		$hud/daftar_properti_objek/panel/translasi_z.min_value = 0.1
		$hud/daftar_properti_objek/panel/translasi_z.max_value = 100
		$hud/daftar_properti_objek/panel/translasi_z.value = edit_objek.skala.z
		$hud/daftar_properti_objek/panel/translasi_x.editable = true
		$hud/daftar_properti_objek/panel/translasi_y.editable = true
		$hud/daftar_properti_objek/panel/translasi_z.editable = true
func _tampilkan_daftar_objek() -> void:
	if $daftar_objek/Panel.anchor_top > 0: $daftar_objek/animasi.play("tampilkan")
	karakter._atur_kendali(false)
	memasang_objek = true
func _tutup_daftar_objek(paksa : bool = false) -> void:
	if is_instance_valid(karakter):
		# kalau paksa berarti kendali pemain gak dikembaliin
		$daftar_objek/animasi.play("sembunyikan")
		if !paksa: karakter._atur_kendali(true)
		memasang_objek = false
func _tambah_translasi_x_objek() -> void:
	$hud/daftar_properti_objek/panel/translasi_x.value += $hud/daftar_properti_objek/panel/translasi_x.step # TODO : jangan tambah dari step
	#_ketika_translasi_x_objek_diubah($hud/daftar_properti_objek/panel/translasi_x.value)
func _kurang_translasi_x_objek() -> void:
	$hud/daftar_properti_objek/panel/translasi_x.value -= $hud/daftar_properti_objek/panel/translasi_x.step
	#_ketika_translasi_x_objek_diubah($hud/daftar_properti_objek/panel/translasi_x.value)
func _tambah_translasi_y_objek() -> void:
	$hud/daftar_properti_objek/panel/translasi_y.value += $hud/daftar_properti_objek/panel/translasi_y.step
	#_ketika_translasi_y_objek_diubah($hud/daftar_properti_objek/panel/translasi_y.value)
func _kurang_translasi_y_objek() -> void:
	$hud/daftar_properti_objek/panel/translasi_y.value -= $hud/daftar_properti_objek/panel/translasi_y.step
	#_ketika_translasi_y_objek_diubah($hud/daftar_properti_objek/panel/translasi_y.value)
func _tambah_translasi_z_objek() -> void:
	$hud/daftar_properti_objek/panel/translasi_z.value += $hud/daftar_properti_objek/panel/translasi_z.step
	#_ketika_translasi_z_objek_diubah($hud/daftar_properti_objek/panel/translasi_z.value)
func _kurang_translasi_z_objek() -> void:
	$hud/daftar_properti_objek/panel/translasi_z.value -= $hud/daftar_properti_objek/panel/translasi_z.step
	#_ketika_translasi_z_objek_diubah($hud/daftar_properti_objek/panel/translasi_z.value)
func _ketika_translasi_x_objek_diubah(nilai : float) -> void:
	if $hud/daftar_properti_objek/panel/translasi_x.editable:
		#Panku.notify("ceritakan padanya~")
		if edit_objek != null:
			await get_tree().create_timer(0.05).timeout
			if $hud/daftar_properti_objek/panel/pilih_tab_posisi.button_pressed:
				edit_objek.set_indexed("global_transform:origin:x", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_rotasi.button_pressed:
				edit_objek.set_indexed("rotation_degrees:x", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_skala.button_pressed:
				edit_objek.set_indexed("skala:x", nilai)
func _ketika_translasi_y_objek_diubah(nilai : float) -> void:
	if $hud/daftar_properti_objek/panel/translasi_y.editable:
		if edit_objek != null:
			await get_tree().create_timer(0.05).timeout
			if $hud/daftar_properti_objek/panel/pilih_tab_posisi.button_pressed:
				edit_objek.set_indexed("global_transform:origin:y", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_rotasi.button_pressed:
				edit_objek.set_indexed("rotation_degrees:y", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_skala.button_pressed:
				edit_objek.set_indexed("skala:y", nilai)
func _ketika_translasi_z_objek_diubah(nilai : float) -> void:
	if $hud/daftar_properti_objek/panel/translasi_z.editable:
		if edit_objek != null:
			await get_tree().create_timer(0.05).timeout
			if $hud/daftar_properti_objek/panel/pilih_tab_posisi.button_pressed:
				edit_objek.set_indexed("global_transform:origin:z", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_rotasi.button_pressed:
				edit_objek.set_indexed("rotation_degrees:z", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_skala.button_pressed:
				edit_objek.set_indexed("skala:z", nilai)
func _ketika_mengubah_kode_objek() -> void:
	if edit_objek != null and edit_objek.get_node_or_null("kode_ubahan") != null:
		# 06/06/24 :: dapatkan kode objek, terapkan kode ke editor, kemudian tampilkan editor
		$blok_kode/panel_kode.buat_blok_kode(edit_objek.get_node("kode_ubahan").dapatkan_kode())
		# 14/06/24 :: # buat palet sintaks berdasarkan kelas objek
		var sintaks_aksi : Dictionary = {
			"Permainan" : [
				["notifikasi(teks)", "Panku.notify(\"teks\")", "ikon"],
				["pesan(teks)", "server.permainan._tampilkan_popup_informasi_(\"teks\")", "ikon"]
			]
		}
		if edit_objek is objek:
			sintaks_aksi.merge({
				"Objek" : [
					["pindahkan(arah)", "get_node(\"../../\").pindahkan(Vector3(0,0,0))", "ikon"]
				]
			})
		$blok_kode/panel_kode.buat_palet_sintaks("%aksi", sintaks_aksi)
		# 11/06/24 :: sambungkan signal jalankan_kode dari editor ke objek
		$blok_kode/panel_kode.connect("jalankan_kode", edit_objek.get_node("kode_ubahan").atur_kode)
		tampilkan_editor_kode()
func _ketika_mengubah_jarak_pandangan_objek(jarak : float) -> void:
	if edit_objek != null:
		if !Input.is_action_pressed("perdekat_pandangan") and !Input.is_action_pressed("perjauh_pandangan"):
			$pengamat.get_node("%pandangan").position.z = jarak
func _tampilkan_popup_informasi(teks_informasi : String, fokus_setelah : Control) -> void:
	# 16/06/24 :: ketika dalam permainan
	if is_instance_valid(karakter) and !jeda: _jeda()
	$popup_informasi.target_fokus_setelah = fokus_setelah
	$popup_informasi/panel/teks.text = teks_informasi
	$popup_informasi/animasi.play_backwards("tutup")
	$popup_informasi/panel/tutup.grab_focus()
func _tampilkan_popup_informasi_(teks_informasi : String) -> void: _tampilkan_popup_informasi(teks_informasi, $menu_jeda/menu/kontrol/Panel/lanjutkan)
func _tutup_popup_informasi() -> void:
	$popup_informasi/animasi.play("tutup")
	await get_tree().create_timer($popup_informasi/animasi.current_animation_length).timeout
	$popup_informasi/panel/teks.text = ""+str(randf())
	$popup_informasi.target_fokus_setelah.grab_focus()
func _tampilkan_popup_konfirmasi(tombol_penampil : Button, fungsi : Callable, teks : String) -> void:
	$popup_konfirmasi.penampil = tombol_penampil
	$popup_konfirmasi.fungsi = fungsi
	$popup_konfirmasi/panel/teks.text = teks
	$popup_konfirmasi/animasi.play("tampilkan")
	$popup_konfirmasi/panel/batal.grab_focus()
func _ketika_konfirmasi_popup_konfirmasi() -> void:
	$popup_konfirmasi/animasi.play_backwards("tampilkan")
	$popup_konfirmasi.fungsi.call()
	$popup_konfirmasi.penampil.grab_focus()
func _tutup_popup_konfirmasi() -> void:
	$popup_konfirmasi/animasi.play("tutup")
	$popup_konfirmasi.penampil.grab_focus()
func _tampilkan_popup_konfirmasi_peringatan(tombol_penampil : Button, fungsi : Callable, teks : String) -> void:
	$popup_konfirmasi_peringatan.penampil = tombol_penampil
	$popup_konfirmasi_peringatan.fungsi = fungsi
	$popup_konfirmasi_peringatan/panel/teks.text = teks
	$popup_konfirmasi_peringatan/panel/proses_konfirmasi.value = 0
	$popup_konfirmasi_peringatan/animasi.play("tampilkan")
	$popup_konfirmasi_peringatan/panel/oke.grab_focus()
	AudioServer.set_bus_effect_enabled(1, 1, true)
func _konfirmasi_peringatan() -> void:
	$popup_konfirmasi_peringatan/animasi.play("proses_konfirmasi")
func _batalkan_konfirmasi_peringatan() -> void:
	$popup_konfirmasi_peringatan/animasi.stop()
	$popup_konfirmasi_peringatan/animasi.get_animation("batalkan_proses_konfirmasi").track_set_key_value(
		0,
		0,
		$popup_konfirmasi_peringatan/panel/proses_konfirmasi.value
	)
	$popup_konfirmasi_peringatan/animasi.play("batalkan_proses_konfirmasi")
func _ketika_proses_konfirmasi_peringatan(persentase : float) -> void:
	if persentase == 100:
		$popup_konfirmasi_peringatan/animasi.play_backwards("tampilkan")
		$popup_konfirmasi_peringatan.fungsi.call()
		$popup_konfirmasi_peringatan.penampil.grab_focus()
func _tutup_popup_konfirmasi_peringatan() -> void:
	$popup_konfirmasi_peringatan/animasi.play("tutup")
	$popup_konfirmasi_peringatan.penampil.grab_focus()
	AudioServer.set_bus_effect_enabled(1, 1, false)
func _mainkan_musik_latar() -> void:
	if $pemutar_musik/AudioStreamPlayer.stream == null:
		var musik : AudioStream = load("res://audio/soundtrack/Animal Crossing Kirara Magic Remix.mp3")
		if musik != null:
			$pemutar_musik/AudioStreamPlayer.stream = musik
			$pemutar_musik/AudioStreamPlayer.play()
			$pemutar_musik/judul.text = "New Horizons (Remix)"
			$pemutar_musik/artis.text = "Kirara Magic"
			$pemutar_musik/posisi_durasi.max_value = $pemutar_musik/AudioStreamPlayer.stream.get_length()
	else:
		$pemutar_musik/AudioStreamPlayer.play()
		$pemutar_musik/posisi_durasi.max_value = $pemutar_musik/AudioStreamPlayer.stream.get_length()
	#pass
func _ketika_musik_latar_selesai_dimainkan() -> void:
	await get_tree().create_timer(10.0).timeout
	_mainkan_musik_latar()
func _hentikan_musik_latar() -> void:
	$pemutar_musik/AudioStreamPlayer.stop()
	$pemutar_musik/AudioStreamPlayer.stream = null
func _tambah_daftar_pemain(id_pemain : int, data_pemain : Dictionary) -> void:
	var pemain = load("res://ui/pemain.tscn").instantiate()
	# INFO : tambahkan info pemain ke daftar pemain
	#print("just a little more~")
	$hud/daftar_pemain/panel/gulir/baris.add_child(pemain)
	pemain.id		= data_pemain["id_sys"]
	pemain.sistem	= data_pemain["sistem"]
	pemain.nama		= data_pemain["nama"]
	pemain.karakter	= data_pemain["gender"]
	pemain.name = str(id_pemain)
	if data_pemain.get("gambar") != null:
		var gambar_pemain = Image.new()
		gambar_pemain.set_data(data_pemain["gambar"]["width"], data_pemain["gambar"]["height"], data_pemain["gambar"]["mipmaps"], Image.FORMAT_RGBA8, data_pemain["gambar"]["data"])
		pemain.atur_gambar_karakter(gambar_pemain)
		if koneksi == MODE_KONEKSI.SERVER:
			pemain.gambar = data_pemain["gambar"]
func _atur_daftar_pemain(id_pemain : int, properti: String, nilai) -> void:
	var tmp_daftar : Control = $hud/daftar_pemain/panel/gulir/baris.get_node_or_null(str(id_pemain))
	if tmp_daftar != null and tmp_daftar.get(properti) != null:
		tmp_daftar.set(properti, nilai)
func _dapatkan_daftar_pemain() -> Array[Node]:
	return $hud/daftar_pemain/panel/gulir/baris.get_children()
func _hapus_daftar_pemain(id_pemain : int) -> void:
	var tmp_daftar : Control = $hud/daftar_pemain/panel/gulir/baris.get_node_or_null(str(id_pemain))
	if tmp_daftar != null:
		$hud/daftar_pemain/panel/gulir/baris.remove_child(tmp_daftar)
		tmp_daftar.queue_free()
func _tampilkan_setelan_permainan() -> void:
	if $pemutar_musik.visible: $pemutar_musik/animasi.play("sembunyikan")
	#Panku.gd_exprenv.execute("setelan.buka_setelan_permainan()") # HACK : eksekusi kode di konsol
	_konfigurasi_awal = {
		"bahasa": Konfigurasi.bahasa,
		"mode_layar_penuh": Konfigurasi.mode_layar_penuh,
		"volume_musik_latar": Konfigurasi.volume_musik_latar,
		"jarak_render": Konfigurasi.jarak_render,
		"mode_kontrol_gerak": Konfigurasi.mode_kontrol_gerak,
		"sensitivitasPandangan": Konfigurasi.sensitivitasPandangan
	}
	$setelan/panel/gulir/tab_setelan/setelan_performa/info_jarak_render/nilai_jarak_render.text = str(Konfigurasi.jarak_render)+"m"
	$setelan/panel/gulir/tab_setelan/setelan_input/info_sensitivitas_gestur/nilai_sensitivitas_gestur.text = str(Konfigurasi.sensitivitasPandangan)
	$setelan/animasi.play("tampilkan")
func _sembunyikan_setelan_permainan() -> void:
	$setelan/animasi.play_backwards("tampilkan")
	# jangan simpan kalo gak ada yang diubah
	var indeks_konfigurasi = _konfigurasi_awal.keys()
	for cfg in _konfigurasi_awal.size():
		if _konfigurasi_awal[indeks_konfigurasi[cfg]] != Konfigurasi.get(indeks_konfigurasi[cfg]):
			Konfigurasi.simpan()
			break
func _tampilkan_input_pesan() -> void:
	$kontrol_sentuh/chat.release_focus()
	if pesan:
		$hud/pesan/layout_input_pesan/input_pesan.release_focus()
		$hud/pesan/daftar_pesan/animasi.play("sembunyikan")
		$hud/pesan/animasi.play("sembunyikan")
		if $daftar_objek/Panel.anchor_top < 1 or edit_objek != null: pass # jangan tangkap mouse ketika menutup input pesan pada saat membuat/mengedit objek
		else:
			$kontrol_sentuh/mic.visible = true
			$kontrol_sentuh/lari.visible = true
			karakter._atur_kendali(true)
		pesan = false
	else:
		$hud/pesan/daftar_pesan/animasi.play("tampilkan")
		$hud/pesan/animasi.play("tampilkan")
		$hud/pesan/layout_input_pesan/input_pesan.grab_focus()  
		if $daftar_objek/Panel.anchor_top < 1 or edit_objek != null: pass # jangan ubah kendali pemain ketika membuka input pesan pada saat membuat/mengedit objek
		else:
			$kontrol_sentuh/mic.visible = false
			$kontrol_sentuh/lari.visible = false
			karakter._atur_kendali(false)
		pesan = true
func _tampilkan_pesan(teks : String) -> void:
	# TODO : rekam ke timeline
	$hud/pesan/daftar_pesan/animasi.play("tampilkan")
	$hud/pesan/daftar_pesan.append_text("\n"+teks)
	if !pesan:
		# 15 karakter = 3 detik
		# jadi 5 karakter = 1 detik
		# dan 1 karakter = 0.2 detik
		_timer_tampilkan_pesan.wait_time = 0.2 * teks.length()
		_timer_tampilkan_pesan.start()
func _sembunyikan_pesan() -> void:
	if !pesan:
		$hud/pesan/daftar_pesan/animasi.play("sembunyikan")
		_timer_tampilkan_pesan.stop()
func _tampilkan_panel_informasi() -> void:
	if $pemutar_musik.visible:
		$pemutar_musik/animasi.play("sembunyikan")
		await get_tree().create_timer($pemutar_musik/animasi.current_animation_length).timeout
	if $setelan.visible:
		_sembunyikan_setelan_permainan()
	if $buat_server.visible:
		$buat_server/animasi.play("animasi_panel/tutup")
		await get_tree().create_timer($buat_server/animasi.current_animation_length).timeout
	elif $daftar_server.visible:
		client.hentikan_pencarian_server()
		$daftar_server/animasi.play("animasi_panel/tutup")
		_reset_daftar_server_lan()
		await get_tree().create_timer($daftar_server/animasi.current_animation_length).timeout
	elif $karakter.visible:
		$karakter/animasi.play("animasi_panel/tutup")
		await get_tree().create_timer($karakter/animasi.current_animation_length).timeout
	$menu_utama/animasi.play("sembunyikan")
	await get_tree().create_timer($menu_utama/animasi.current_animation_length).timeout
	$informasi/animasi.play("tampilkan")
	$informasi/panel/oke.grab_focus()
func _sembunyikan_panel_informasi() -> void:
	$informasi/animasi.play("tutup")
	$menu_utama/animasi.play("tampilkan")
	await get_tree().create_timer($menu_utama/animasi.current_animation_length).timeout
	$menu_utama/menu/Panel/buat_server.grab_focus()
func _ketika_menekan_link_informasi(tautan : String) -> void:
	if tautan != "":
		var t_inf_link = TranslationServer.translate("%tinggalkan_permainan")
		var fungsi_buka_tautan = Callable(OS, "shell_open")
		_tampilkan_popup_konfirmasi_peringatan($informasi/panel/oke, fungsi_buka_tautan.bind(tautan), t_inf_link % [tautan])
func _laporkan_bug() -> void: _ketika_menekan_link_informasi("https://github.com/zinzui12345/dreamline/issues")
func _sarankan_fitur() -> void:
	pass
func _ketika_mengatur_informasi_performa(visibilitas : bool) -> void:
	$performa.visible = visibilitas
	$versi.visible = visibilitas
func _buka_log() -> void:
	var aa = Panku.module_manager.get_module("native_logger")
	aa.open_window()
func _tampilkan_konsol() -> void: Panku.toggle_console_action_just_pressed.emit()
func lepaskan_kursor_mouse() -> void: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
func berhenti_mengedit_objek() -> void:
	if edit_objek != null:
		server.edit_objek(edit_objek.name, false)
func tampilkan_editor_kode() -> void:
	if !is_instance_valid(karakter):
		if $pemutar_musik.visible:
			$pemutar_musik/animasi.play("sembunyikan")
		if $daftar_server.visible:
			$daftar_server/animasi.play("animasi_panel/tutup")
		if $karakter.visible:
			$karakter/animasi.play("animasi_panel/tutup")
		$menu_utama/animasi.play("lipat")
	if OS.get_distribution_name() == "Android":
		$blok_kode/panel_kode._ketika_mengatur_skala(1.5)
		$blok_kode/panel_kode/kontrol_skala/pengatur_skala.value = 1.5
	$blok_kode/animasi.play("tampilkan")
func tutup_editor_kode() -> void:
	# 07/06/24 :: hapus node blok kode untuk mengurangi penggunaan memori
	$blok_kode/panel_kode.hapus_blok_kode()
	# 14/06/24 :: hapus palet sintaks untuk mengurangi penggunaan memori
	$blok_kode/panel_kode.hapus_palet_sintaks()
	# 11/06/24 :: putuskan signal jalankan_kode dari editor ke objek
	if is_instance_valid(edit_objek) and $blok_kode/panel_kode.is_connected("jalankan_kode", edit_objek.get_node("kode_ubahan").atur_kode):
		$blok_kode/panel_kode.disconnect("jalankan_kode", edit_objek.get_node("kode_ubahan").atur_kode)
	# kalau bukan dalam permainan, tampilkan kembali menu utama
	if !is_instance_valid(karakter):
		$menu_utama/animasi.play("perluas")
	$blok_kode/animasi.play("sembunyikan")
func tampilkan_dialog(file_dialog : DialogueResource) -> void:
	var penampil_dialog : Node = load("res://ui/dialog.tscn").instantiate()
	$dialog.add_child(penampil_dialog)
	penampil_dialog.start(file_dialog, "0", [])
	if is_instance_valid(karakter):
		karakter._atur_kendali(false)
		karakter._atur_penarget(false)
func tutup_dialog(_file_dialog : Resource) -> void:
	if is_instance_valid(karakter):
		if Input.is_action_pressed("lompat"): Input.action_release("lompat")
		karakter._atur_kendali(true)
		karakter._atur_penarget(true)

# karakter
func _ketika_mengubah_nama_karakter(nama): data["nama"] = nama
func _ketika_mengubah_gender_karakter(gender):
	get_node("%karakter/lulu").visible = false
	get_node("%karakter/reno").visible = false
	match gender:
		0: data["gender"] = "P"; get_node("%karakter/lulu").visible = true
		1: data["gender"] = "L"; get_node("%karakter/reno").visible = true
func _ketika_mengubah_alis_karakter(id_alis):
	data["alis"] = id_alis
	get_node("%karakter/lulu").model["alis"] = id_alis
	get_node("%karakter/lulu").atur_model()
	get_node("%karakter/reno").model["alis"] = id_alis
	get_node("%karakter/reno").atur_model()
func _ketika_mengubah_bentuk_bulu_mata_karakter(id_model):
	data["garis_mata"] = id_model
	get_node("%karakter/lulu").model["garis_mata"] = id_model
	get_node("%karakter/lulu").atur_model()
	get_node("%karakter/reno").model["garis_mata"] = id_model
	get_node("%karakter/reno").atur_model()
func _ketika_mengubah_bentuk_mata_karakter(id_model):
	data["mata"] = id_model
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter/lulu.model["mata"] = id_model
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter/lulu.atur_model()
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter/reno.model["mata"] = id_model
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter/reno.atur_model()
func _ketika_mengubah_warna_mata_karakter(warna):
	var tmp_warna : Color = Color(str(warna))
	data["warna_mata"] = tmp_warna
	get_node("%karakter/lulu").warna["mata"] = tmp_warna
	get_node("%karakter/lulu").atur_warna()
	get_node("%karakter/reno").warna["mata"] = tmp_warna
	get_node("%karakter/reno").atur_warna()
func _ketika_mengubah_rambut_karakter(id_model):
	data["rambut"] = id_model
	get_node("%karakter/lulu").model["rambut"] = id_model
	get_node("%karakter/lulu").atur_model()
	get_node("%karakter/reno").model["rambut"] = id_model
	get_node("%karakter/reno").atur_model()
func _ketika_mengubah_warna_rambut_karakter(warna):
	var tmp_warna : Color = Color(str(warna))
	data["warna_rambut"] = tmp_warna
	get_node("%karakter/lulu").warna["rambut"] = tmp_warna
	get_node("%karakter/lulu").atur_warna()
	get_node("%karakter/reno").warna["rambut"] = tmp_warna
	get_node("%karakter/reno").atur_warna()
func _ketika_mengubah_baju_karakter(id_model):
	data["baju"] = id_model
	get_node("%karakter/lulu").model["baju"] = id_model
	get_node("%karakter/lulu").atur_model()
	get_node("%karakter/reno").model["baju"] = id_model
	get_node("%karakter/reno").atur_model()
func _ketika_mengubah_warna_baju_karakter(warna):
	var tmp_warna : Color = Color(str(warna))
	data["warna_baju"] = tmp_warna
	get_node("%karakter/lulu").warna["baju"] = tmp_warna
	get_node("%karakter/lulu").atur_warna()
	get_node("%karakter/reno").warna["baju"] = tmp_warna
	get_node("%karakter/reno").atur_warna()
func _ketika_mengubah_celana_karakter(id_model):
	data["celana"] = id_model
	get_node("%karakter/lulu").model["celana"] = id_model
	get_node("%karakter/lulu").atur_model()
	get_node("%karakter/reno").model["celana"] = id_model
	get_node("%karakter/reno").atur_model()
func _ketika_mengubah_warna_celana_karakter(warna):
	var tmp_warna : Color = Color(str(warna))
	data["warna_celana"] = tmp_warna
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter/lulu.warna["celana"] = tmp_warna
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter/lulu.atur_warna()
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter/reno.warna["celana"] = tmp_warna
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter/reno.atur_warna()
func _ketika_mengubah_sepatu_karakter(id_model):
	data["sepatu"] = id_model
	get_node("%karakter/lulu").model["sepatu"] = id_model
	get_node("%karakter/lulu").atur_model()
	get_node("%karakter/reno").model["sepatu"] = id_model
	get_node("%karakter/reno").atur_model()
func _ketika_mengubah_warna_sepatu_karakter(warna):
	var tmp_warna : Color = Color(str(warna))
	data["warna_sepatu"] = warna
	get_node("%karakter/lulu").warna["sepatu"] = tmp_warna
	get_node("%karakter/lulu").atur_warna()
	get_node("%karakter/reno").warna["sepatu"] = tmp_warna
	get_node("%karakter/reno").atur_warna()
func _ketika_menyimpan_data_karakter():
	var file = FileAccess.open(Konfigurasi.data_pemain, FileAccess.WRITE)
	file.store_var(data)
	file.close()
	Panku.notify("%simpan_karakter")

# menu
func _jeda():
	if is_instance_valid(karakter) and karakter.has_method("_atur_kendali"):
		if get_node_or_null("pengamat") != null and !server.mode_replay \
			and !server.mode_uji_performa and $pengamat/kamera/rotasi_vertikal/pandangan.current:
			pass
		else:
			if memasang_objek: _tutup_daftar_objek(true)
			if $dialog.get_node_or_null("ExampleBalloon") != null:
				$dialog.get_node("ExampleBalloon").fade_out()
			karakter._atur_kendali(false)
		$mode_bermain.visible = false
		$kontrol_sentuh/menu.visible = false
		$kontrol_sentuh/chat.visible = false
		$menu_jeda/menu/animasi.play("tampilkan")
		$menu_jeda/menu/kontrol/Panel/lanjutkan.grab_focus()
		jeda = true
func _lanjutkan():
	if $setelan.visible: _sembunyikan_setelan_permainan()
	if is_instance_valid(karakter) and karakter.has_method("_atur_kendali"):
		if is_instance_valid(edit_objek): pass
		elif $dialog.get_node_or_null("ExampleBalloon") != null:
			$dialog.get_node("ExampleBalloon").fade_in()
		else: karakter._atur_kendali(true)
		$mode_bermain.visible = true
		$kontrol_sentuh/menu.visible = true
		$kontrol_sentuh/chat.visible = true
		$menu_jeda/menu/animasi.play("sembunyikan")
		$menu_jeda/menu/kontrol/Panel/lanjutkan.release_focus()
		jeda = false
func _kembali():
	if $popup_informasi.visible:
		_tutup_popup_informasi()
	elif $popup_konfirmasi.visible:
		_tutup_popup_konfirmasi()
	elif $popup_konfirmasi_peringatan.visible:
		_tutup_popup_konfirmasi_peringatan()
	elif $proses_koneksi.visible:
		client.putuskan_server()
		$proses_koneksi/animasi.play("sembunyikan")
	elif $blok_kode.visible:
		tutup_editor_kode()
	elif $setelan.visible:
		_sembunyikan_setelan_permainan()
	elif $buat_server.visible:
		_sembunyikan_konfigurasi_server()
	elif $daftar_server.visible:
		_sembunyikan_daftar_server()
	elif $karakter.visible:
		_sembunyikan_setelan_karakter()
	elif $informasi.visible:
		_sembunyikan_panel_informasi()
	elif !is_instance_valid(karakter):
		_keluar()
func _putuskan():
	putuskan_server()
func _keluar():
	_tampilkan_popup_konfirmasi($menu_utama/keluar, Callable(get_tree(), "quit"), "%keluar%")

# konfigurasi
func _ketika_mengatur_mode_layar_penuh(nilai):
	if not $setelan/panel/gulir/tab_setelan/setelan_umum/layar_penuh.disabled:
		Konfigurasi.mode_layar_penuh = nilai
func _ketika_mengatur_bahasa(nilai):
	if not $setelan/panel/gulir/tab_setelan/setelan_umum/pilih_bahasa.disabled:
		Konfigurasi.bahasa = nilai
func _ketika_mengatur_volume_musik_latar(nilai):
	if $setelan/panel/gulir/tab_setelan/setelan_suara/volume_musik.editable:
		Konfigurasi.volume_musik_latar = nilai
func _ketika_mengatur_jarak_render(jarak):
	if is_instance_valid(dunia) and dunia.get_node_or_null("lingkungan") != null:
		dunia.get_node("pemain/"+str(multiplayer.get_unique_id())+"/%pandangan").set("far", jarak)
	if $setelan/panel/gulir/tab_setelan/setelan_performa/jarak_render.editable:
		Konfigurasi.jarak_render = jarak
	$setelan/panel/gulir/tab_setelan/setelan_performa/info_jarak_render/nilai_jarak_render.text = str(jarak)+"m"
func _ketika_mengatur_mode_kontrol_gerak(mode):
	$kontrol_sentuh/kontrol_gerakan/analog.visible = false
	$"kontrol_sentuh/kontrol_gerakan/d-pad".visible = false
	match mode:
		0: $kontrol_sentuh/kontrol_gerakan/analog.visible = true
		1: $"kontrol_sentuh/kontrol_gerakan/d-pad".visible = true
	if not $setelan/panel/gulir/tab_setelan/setelan_input/pilih_kontrol_gerak.disabled:
		Konfigurasi.mode_kontrol_gerak = mode
func _ketika_mengatur_sensitivitas_pandangan(nilai):
	if $setelan/panel/gulir/tab_setelan/setelan_input/sensitivitas_gestur.editable:
		Konfigurasi.sensitivitasPandangan = nilai
	$setelan/panel/gulir/tab_setelan/setelan_input/info_sensitivitas_gestur/nilai_sensitivitas_gestur.text = str(nilai)

# fungsi lain
func detikKeMenit(detik: int) -> String:
	var menit = ceil(detik) / 60
	var detik_tersisa = detik % 60

	var menit_terformat = str(menit)
	var detik_terformat = str(detik_tersisa)

	# Menambahkan nol di depan jika menit atau detik kurang dari 10
	if menit < 10:
		menit_terformat = "0" + menit_terformat

	if detik_tersisa < 10:
		detik_terformat = "0" + detik_terformat

	return menit_terformat + ":" + detik_terformat
func hasilkanKarakterAcak(jumlah: int) -> String:
	var set_karakter = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
	var length = set_karakter.length()
	var karakter_acak = ""
	for i in range(jumlah):
		var indeks_acak = randi_range(0, length - 1)
		karakter_acak += set_karakter[indeks_acak]
	return karakter_acak
func tampilkan_info_koneksi():
	# Dapatkan IP
	var addr : Array
	addr = IP.get_local_interfaces()
	var ipinf: String = ""
	if koneksi == MODE_KONEKSI.SERVER and OS.get_name() != "Windows":
		for dev in addr.size():
			var addrdata = addr[dev]
			ipinf += str(addrdata["name"]) + " : " + str(addrdata["addresses"][0]) + "\n"
	else: ipinf = str(client.id_koneksi)
	$hud/daftar_pemain/panel/informasi/alamat_ip.text = ipinf
func mainkan_replay():
	if FileAccess.file_exists(server.file_replay):
		var file_rekaman = FileAccess.open(server.file_replay, FileAccess.READ)
		if file_rekaman != null:
			var rekaman = file_rekaman.get_var()
			server.timeline = rekaman
			server.timeline["entitas"] = {}
			server.timeline["trek"] = {}
			server.mode_replay = true
			koneksi = MODE_KONEKSI.CLIENT
			_mulai_permainan("replay", rekaman.data.map)
			$hud/daftar_pemain/panel/informasi/alamat_ip.text = "-"
	else: return "tidak ada file rekaman permainan!"

# bantuan pada console
const _HELP_alamat_ip			:= "Cek alamat IP Lokal/Publik koneksi"
const _HELP_cek_koneksi_server	:= "Cek status koneksi dengan server"
const _HELP_putuskan_server 	:= "Hentikan/Putuskan server [fungsi ini dipanggil secara otomatis!] * memanggilnya secara manual akan membiarkan kursor mouse dalam kondisi capture"
const _HELP_PERAN_KARAKTER		:= "Tipe-tipe peran yang dapat diperankan karakter/pemain" # gak work!
