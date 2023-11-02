extends Control

class_name Permainan

## ChangeLog ##
# 07 Jul 2023 | 1.3.9 - Implementasi LAN Server berbasis Cross-Play
# 04 Agu 2023 | 1.3.9 - Implementasi Timeline
# 09 Agu 2023 | 1.4.0 - Voice Chat telah berhasil di-implementasikan : Metode optimasi yang digunakan adalah metode kompresi ZSTD
# 11 Agu 2023 | 1.4.0 - Penerapan notifikasi PankuConsole dan tampilan durasi timeline
# 14 Agu 2023 | 1.4.0 - Implementasi Terrain : Metode optimasi menggunakan Frustum Culling dan Object Culling
# 15 Agu 2023 | 1.4.1 - Implementasi Vegetasi Terrain : Metode optimasi menggunakan RenderingServer / Low Level Rendering
# 06 Sep 2023 | 1.4.1 - Perubahan animasi karakter dan penerapan Animation Retargeting pada karakter
# 18 Sep 2023 | 1.4.1 - Implementasi shader karakter menggunakan MToon
# 21 Sep 2023 | 1.4.2 - Perbaikan karakter dan penempatan posisi kamera First Person
# 23 Sep 2023 | 1.4.2 - Penambahan entity posisi spawn pemain
# 25 Sep 2023 | 1.4.2 - Penambahan Text Chat
# 09 Okt 2023 | 1.4.3 - Mode kamera kendaraan dan kontrol menggunakan arah pandangan
# 10 Okt 2023 | 1.4.3 - Penambahan senjata Bola salju raksasa
# 12 Okt 2023 | 1.4.3 - Tombol Sentuh Fleksibel
# 14 Okt 2023 | 1.4.4 - Penambahan Mode Edit Objek
# 21 Okt 2023 | 1.4.4 - Mode Edit Objek telah berhasil di-implementasikan
# 31 Okt 2023 | 1.4.4 - Perbaikan kesalahan kontrol sentuh

const versi = "Dreamline beta v1.4.4 rev 01/11/23 alpha"
const karakter_cewek = preload("res://karakter/rulu/rulu.scn")
const karakter_cowok = preload("res://karakter/reno/reno.scn")

var data = {
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
var dunia = null
var map = null
var permukaan					# Permukaan (Terrain)
var batas_bawah = -4000			# batas area untuk re-spawn
var edit_objek : Node3D			# ref objek yang sedang di-edit
var memasang_objek = false
var pasang_objek : Vector3		# posisi objek yang akan dipasang
var thread = Thread.new()
var koneksi = MODE_KONEKSI.CLIENT
var jeda = false
var pesan = false				# ketika input pesan ditampilkan
var _posisi_tab_koneksi = "LAN" # | "Internet"
var _rotasi_tampilan_karakter : Vector3
var _rotasi_tampilan_objek : Vector3
var _arah_gestur_tampilan_karakter : Vector2
var _arah_gestur_tampilan_objek : Vector2
var _touchpad_disentuh = false
var _arah_sentuhan_touchpad : Vector2
var _timer_kirim_suara = Timer.new()
var _timer_tampilkan_pesan = Timer.new()
var tombol_aksi_2 = "angkat_sesuatu" :
	set(ikon):
		if ikon != tombol_aksi_2:
			get_node("kontrol_sentuh/aksi_2").set("texture_normal", load("res://ui/tombol/%s.svg" % [ikon]))
			tombol_aksi_2 = ikon
var tombol_aksi_3 = "berlari" :
	set(ikon):
		if ikon != tombol_aksi_3:
			get_node("kontrol_sentuh/lari").set("texture_normal", load("res://ui/tombol/%s.svg" % [ikon]))
			tombol_aksi_3 = ikon

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

func _enter_tree():
	get_tree().get_root().set("min_size", Vector2(980, 600))
func _ready():
	if dunia == null:
		dunia = await load("res://skena/dunia.scn").instantiate()
		get_tree().get_root().call_deferred("add_child", dunia)
	# INFO : (1) non-aktifkan proses untuk placeholder karakter
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
	get_node("%karakter/lulu").warna["celana"] 		= data["warna_celana"]
	get_node("%karakter/lulu").model["sepatu"] 		= data["sepatu"]
	get_node("%karakter/lulu").warna["sepatu"] 		= data["warna_sepatu"]
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
	get_node("%karakter/reno").warna["celana"] 		= data["warna_celana"]
	get_node("%karakter/reno").model["sepatu"] 		= data["sepatu"]
	get_node("%karakter/reno").warna["sepatu"] 		= data["warna_sepatu"]
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
	# INFO : (2) muat data konfigurasi atau terapkan konfigurasi default
	if OS.get_distribution_name() == "Android": Konfigurasi.mode_kontrol_sentuh = true # aktifkan otomatis kontrol sentuh di android
	# INFO : (3) tampilkan menu utama
	$menu_utama/animasi.play("tampilkan")
	$menu_utama/menu/Panel/buat_server.grab_focus()
	$latar.tampilkan()
	_mainkan_musik_latar()

func _process(delta):
	# tampilan karakter di setelan karakter
	_rotasi_tampilan_karakter = Vector3(0, _arah_gestur_tampilan_karakter.x, 0) * (Konfigurasi.sensitivitasPandangan * 2) * delta
	_rotasi_tampilan_objek = Vector3(_arah_gestur_tampilan_objek.y, _arah_gestur_tampilan_objek.x, 0) * (Konfigurasi.sensitivitasPandangan * 2) * delta
	if $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y < -360:
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y += 360
	if $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y > 360:
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y -= 360
	if $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y <= -180:
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y += 90 * 4
	if $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y >= 180:
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y -= 90 * 4
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y -= _rotasi_tampilan_karakter.y
	$pengamat/kamera/rotasi_vertikal.rotation_degrees.x += _rotasi_tampilan_objek.x
	$pengamat/kamera.rotation_degrees.y -= _rotasi_tampilan_objek.y
	
	# pemutar musik
	if $pemutar_musik.visible:
		$pemutar_musik/posisi_durasi.value = $pemutar_musik/AudioStreamPlayer.get_playback_position()
		$pemutar_musik/durasi.text = "%s/%s" % [
			detikKeMenit($pemutar_musik/posisi_durasi.value), 
			detikKeMenit($pemutar_musik/posisi_durasi.max_value)
		]
	
	# frekuensi mikrofon
	if $hud/frekuensi_mic.visible:
		var idx = AudioServer.get_bus_index("Suara Pemain")
		var effect = AudioServer.get_bus_effect_instance(idx, 1)
		var magnitude : float = effect.get_magnitude_for_frequency_range(1, 11050.0 / 4).length()
		var energy = clamp((60 + linear_to_db(magnitude)) / 60, 0, 1)
		$hud/frekuensi_mic/posisi/persentasi.value = energy * 100
	
	# input
	if is_instance_valid(karakter): # ketika dalam permainan
		if Input.is_action_just_pressed("ui_cancel"):
			if pesan: _tampilkan_input_pesan()
			elif edit_objek != null: _berhenti_mengedit_objek()
			elif !jeda: _jeda()
			else: _lanjutkan()
		if Input.is_action_pressed("berbicara") and !pesan: _berbicara(true)
		if Input.is_action_just_pressed("daftar_pemain") and (edit_objek == null and !jeda):
			$hud/daftar_pemain/animasi.play("tampilkan")
		if Input.is_action_just_pressed("tampilkan_pesan") and !jeda: _tampilkan_input_pesan()
		if Input.is_action_just_pressed("ui_text_completion_accept") and pesan: _kirim_pesan()
		
		if Input.is_action_just_released("berbicara"): _berbicara(false)
		if Input.is_action_just_released("daftar_pemain") and $hud/daftar_pemain/panel.anchor_left > -1:
			$hud/daftar_pemain/animasi.play_backwards("tampilkan")
		
		if Input.is_action_just_pressed("perdekat_pandangan") or Input.is_action_just_pressed("perjauh_pandangan"):
			if $hud/daftar_properti_objek/DragPad.kontrol:
				$pengamat/posisi_mata.fungsi_zoom = true
			else:
				$pengamat/posisi_mata.fungsi_zoom = false
	
	if Input.is_action_just_pressed("ui_cancel"): _kembali()
	if Input.is_action_just_pressed("modelayar_penuh"):
		if Konfigurasi.mode_layar_penuh:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			Konfigurasi.mode_layar_penuh = false
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			Konfigurasi.mode_layar_penuh = true
		Panku.notify("modelayar_penuh : "+str(Konfigurasi.mode_layar_penuh))
	
	# jangan sembunyikan tombol tutup edit objek
	if is_instance_valid(edit_objek) and !$kontrol_sentuh/aksi_2.visible:
		$kontrol_sentuh/aksi_2.visible = true
	
	# informasi
	var info_mode_koneksi = ""
	match koneksi:
		0: info_mode_koneksi = "server"
		1: info_mode_koneksi = "client"
	if $performa.visible:
		var info_jumlah_entitas = 0
		if is_instance_valid(dunia): info_jumlah_entitas = dunia.get_node("entitas").get_child_count()
		$performa.text = "%s : %s | %s : %s  | %s : %s | VRAM : %s" % [
			TranslationServer.translate("VERTEKS"),
			str(get_tree().get_root().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)),
			TranslationServer.translate("ENTITAS"),
			info_jumlah_entitas,
			TranslationServer.translate("DRAW"),
			RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			String.humanize_size(RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED))
		]
	$versi.text = versi+" | "+String.humanize_size(OS.get_static_memory_usage()+OS.get_static_memory_peak_usage())+" | "+str(Engine.get_frames_per_second())+" fps | "+info_mode_koneksi
func _notification(what):
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if is_instance_valid(karakter): # ketika dalam permainan
			if pesan: _tampilkan_input_pesan()
			elif edit_objek != null: _berhenti_mengedit_objek()
			elif !jeda: _jeda()
			else: _lanjutkan()
		else: _kembali()
	elif what == NOTIFICATION_WM_ABOUT: _tampilkan_panel_informasi()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST: _keluar()
	elif what == NOTIFICATION_CRASH: putuskan_server(true); print_debug("always fading~")

# core
func atur_map(nama_map : StringName = "pulau"):
	if FileAccess.file_exists("res://map/%s.tscn" % [nama_map]): server.map = nama_map; return "mengatur map menjadi : "+nama_map
	else: print("file [res://map/%s.tscn] tidak ditemukan" % [nama_map]);				return "map ["+nama_map+"] tidak ditemukan"
func _mulai_permainan(nama_map = "showcase", posisi = Vector3.ZERO, rotasi = Vector3.ZERO):
	if $pemutar_musik.visible:
		$pemutar_musik/animasi.play("sembunyikan")
	if $daftar_server.visible:
		$daftar_server/animasi.play("animasi_panel/tutup")
		_reset_daftar_server_lan()
	if $karakter.visible:
		$karakter/animasi.play("animasi_panel/tutup")
	if $karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter.visible:
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter.visible = false
	if $karakter/panel/tampilan/SubViewportContainer/SubViewport.get_node_or_null("pencahayaan_karakter") != null:
		var tmp_p = $karakter/panel/tampilan/SubViewportContainer/SubViewport.get_node("pencahayaan_karakter")
		$karakter/panel/tampilan/SubViewportContainer/SubViewport.remove_child(tmp_p)
		tmp_p.queue_free()
		for t_karakter in get_node("%karakter").get_children(): t_karakter.queue_free()
	$karakter/panel/tampilan/SubViewportContainer/SubViewport/lantai/CollisionShape3D.disabled = true
	if $proses_koneksi.visible:
		_sembunyikan_proses_koneksi()
	$menu_utama/animasi.play("sembunyikan")
	$proses_memuat/panel_bawah/animasi.play("tampilkan")
	$proses_memuat/panel_bawah/Panel/SpinnerMemuat/AnimationPlayer.play("kuru_kuru")
	$proses_memuat/panel_bawah/Panel/PersenMemuat.text = "0%"
	$proses_memuat/panel_bawah/Panel/ProsesMemuat.value = 0
	await get_tree().create_timer(1.0).timeout
	data["posisi"] = posisi
	data["rotasi"] = rotasi
	var tmp_perintah = Callable(self, "_muat_map")
	thread.start(tmp_perintah.bind(nama_map), Thread.PRIORITY_NORMAL)
func _muat_map(file_map):
	# INFO : (4) muat map
	map = await load("res://map/%s.tscn" % [file_map]).instantiate()
	map.name = "lingkungan"
	if map.get_node_or_null("posisi_spawn") != null:
		data["posisi"] = map.get_node("posisi_spawn").position
		data["rotasi"] = map.get_node("posisi_spawn").rotation
	if map.get_node_or_null("batas_bawah") != null:
		batas_bawah = map.get_node("batas_bawah").position.y
	call_deferred("_atur_persentase_memuat", 70)
	dunia.call_deferred("add_child", map)
	if koneksi == MODE_KONEKSI.SERVER:
		# INFO : (5a) buat server
		server.call_deferred("buat_koneksi")
		if !server.headless:
			call_deferred("_tambahkan_pemain", 1, data)
			server.pemain_terhubung = 1
	elif koneksi == MODE_KONEKSI.CLIENT:
		# INFO : (5b1) kirim data pemain ke server
		server.call_deferred("rpc_id", 1, "_tambahkan_pemain_ke_dunia", client.id_koneksi, OS.get_unique_id(), data)
		# INFO : (5b3) request objek dari server
		server.call_deferred("rpc_id", 1, "_kirim_objek_ke_pemain", client.id_koneksi)
		#_tampilkan_permainan() # dipindah ke pemain.gd supaya gak lag
	thread.call_deferred("wait_to_finish")
func _tambahkan_pemain(id: int, data_pemain):
	var pemain
	var sumber = "" # ini jalur resource pemain, fungsinya untuk disimpan di timeline
	if is_instance_valid(dunia) and koneksi == MODE_KONEKSI.SERVER: # ini maksudnya cuma dijalanin di server untuk semua (peer) pemain
		match data_pemain["gender"]:
			"L": pemain = karakter_cowok.instantiate(); sumber = karakter_cowok.resource_path
			"P": pemain = karakter_cewek.instantiate(); sumber = karakter_cewek.resource_path
		if !is_instance_valid(pemain): print("tidak dapat menambahkan pemain "+str(id)); return
		
		# INFO : (6) terapkan data pemain ke model pemain
		pemain.id_pemain = id
		pemain.name = str(id)
		pemain.nama 				= data_pemain["nama"]
		pemain.gender 				= data_pemain["gender"]
		pemain.id_sistem			= data_pemain["id_sys"]
		pemain.platform_pemain 		= data_pemain["sistem"]
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
		
		# terapkan kondisi | note : ini harus sebelum pemain ditambahin ke dunia supaya sync dengan ServerSynchronizer
		pemain.position = data_pemain["posisi"]
		pemain.rotation = data_pemain["rotasi"]
		
		# INFO : (7) tambahkan pemain ke dunia
		dunia.get_node("pemain").add_child(pemain, true)
		
		# Timeline : spawn pemain
		server.timeline[server.timeline["data"]["frame"]] = {
			id: {
				"tipe": 		"spawn",
				"tipe_entitas": "pemain",
				"sumber": 		sumber,
				"data": 		data_pemain
			}
		}
		
		# hanya pada server
		if id == 1:
			# INFO : tambah info pemain (server) ke daftar pemain
			_tambah_daftar_pemain(pemain.id_pemain, {
				"nama"	: pemain.nama,
				"sistem": pemain.platform_pemain,
				"id_sys": pemain.id_sistem,
				"gender": pemain.gender
			})
			
			# INFO : (8a) mulai permainan
			karakter = pemain
			pemain._kendalikan(true)
			_tampilkan_permainan()
		
	else: print("tidak dapat menambahkan pemain sebelum memuat dunia!")
func _berbicara(fungsi : bool):
	var idx = AudioServer.get_bus_index("Suara Pemain")
	var effect = AudioServer.get_bus_effect(idx, 0)
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
func _kirim_suara():
	if $suara_pemain.playing:
		var idx = AudioServer.get_bus_index("Suara Pemain")
		var effect = AudioServer.get_bus_effect(idx, 0)
		var tmp_suara = effect.get_recording()
		var tmp_ukuran_buffer_suara = 0
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
func _kirim_pesan():
	if $hud/pesan/input_pesan.text != "":
		if koneksi == MODE_KONEKSI.SERVER: server._terima_pesan_pemain(1, $hud/pesan/input_pesan.text)
		else: server.rpc_id(1, "_terima_pesan_pemain", client.id_koneksi, $hud/pesan/input_pesan.text)
		$hud/pesan/input_pesan.text = ""
	$hud/pesan/input_pesan.release_focus()
	$hud/pesan/input_pesan.grab_focus()
func _edit_objek(jalur): 
	edit_objek = get_node(jalur)
	karakter._atur_kendali(false)
	karakter.get_node("PlayerInput").atur_raycast(false)
	$pengamat/kamera/rotasi_vertikal/pandangan.make_current()
	$kontrol_sentuh/menu.visible = false
	$kontrol_sentuh/chat.visible = false
	$kontrol_sentuh/lari.visible = false
	$kontrol_sentuh/aksi_1.visible = false
	$kontrol_sentuh/lompat.visible = false
	$kontrol_sentuh/kontrol_gerakan.visible = false
	$kontrol_sentuh/kontrol_pandangan.visible = false
	$hud/daftar_properti_objek/animasi.play("tampilkan")
	$hud/daftar_properti_objek/panel/jalur.text = jalur
	$mode_bermain.visible = false
	_pilih_tab_posisi_objek()
	tombol_aksi_2 = "tutup_panel_objek"
	_touchpad_disentuh = false
	# TODO : bikin petunjuk arah sumbu, nonaktifkan visibilitas kompas
	# dapetin properti lain objek; mis. warna, kondisi
	for p in $hud/daftar_properti_objek/panel/properti_kustom/baris.get_children(): p.visible = false
	if edit_objek.get("warna_1") != null:
		$hud/daftar_properti_objek/panel/properti_kustom.visible = true
		$hud/daftar_properti_objek/panel/properti_kustom/baris/warna_1.atur_nilai(edit_objek.get("warna_1"))
		$hud/daftar_properti_objek/panel/properti_kustom/baris/warna_1.visible = true
	if edit_objek.get("warna_2") != null:
		$hud/daftar_properti_objek/panel/properti_kustom.visible = true
		$hud/daftar_properti_objek/panel/properti_kustom/baris/warna_2.atur_nilai(edit_objek.get("warna_2"))
		$hud/daftar_properti_objek/panel/properti_kustom/baris/warna_2.visible = true
func _berhenti_mengedit_objek():
	$hud/daftar_properti_objek/animasi.play("sembunyikan")
	$hud/daftar_properti_objek/panel/properti_kustom.visible = false
	$hud/daftar_properti_objek/panel/pilih_tab_posisi.release_focus()
	$hud/daftar_properti_objek/panel/pilih_tab_rotasi.release_focus()
	$hud/daftar_properti_objek/panel/pilih_tab_skala.release_focus()
	tombol_aksi_2 = "edit_objek"
	$mode_bermain.visible = true
	$kontrol_sentuh/chat.visible = true
	$kontrol_sentuh/menu.visible = true
	$kontrol_sentuh/lari.visible = true
	$kontrol_sentuh/aksi_1.visible = true
	$kontrol_sentuh/lompat.visible = true
	$kontrol_sentuh/kontrol_gerakan.visible = true
	$kontrol_sentuh/kontrol_pandangan.visible = true
	edit_objek = null
	$pengamat/kamera/rotasi_vertikal/pandangan.clear_current()
	karakter._kendalikan(true)
	karakter.get_node("PlayerInput").atur_raycast(true)

# koneksi
func buat_server(headless = false):
	koneksi = MODE_KONEKSI.SERVER
	server.headless = headless
	if $daftar_server.visible:
		client.hentikan_pencarian_server()
		$daftar_server/animasi.play("animasi_panel/tutup")
	_mulai_permainan(server.map)
func gabung_server():
	koneksi = MODE_KONEKSI.CLIENT
	var ip = $daftar_server/panel/panel_input/input_ip.text
	if not ip.is_valid_ip_address():
		if ip == "": 	_tampilkan_popup_informasi("%ipkosong",   $daftar_server/panel/panel_input/input_ip)
		else:			_tampilkan_popup_informasi("%iptakvalid", $daftar_server/panel/panel_input/input_ip)
		return
	$daftar_server/panel/panel_input/input_ip.grab_focus()
	$proses_koneksi/animasi.play("tampilkan")
	$proses_koneksi/panel/animasi.play("proses")
	client.hentikan_pencarian_server()
	client.sambungkan_server(ip)
func cari_server(): 		client.cari_server()
func cek_koneksi_server(): 	client.cek_koneksi()
func putuskan_server(paksa = false):
	if is_instance_valid(dunia):
		if koneksi == MODE_KONEKSI.SERVER:
			if server.pemain_terhubung > 1 and !paksa:
				var tmp_f_putuskan = Callable(self, "putuskan_server")
				tmp_f_putuskan = tmp_f_putuskan.bind(true)
				_tampilkan_popup_konfirmasi($menu_utama/menu/Panel/buat_server, tmp_f_putuskan, "%putuskan_server")
				return
			else:
				server.putuskan()
				$menu_utama/menu/Panel/buat_server.grab_focus()
		elif koneksi == MODE_KONEKSI.CLIENT:
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
		get_node("%karakter/lulu").warna["celana"] 		= data["warna_celana"]
		get_node("%karakter/lulu").model["sepatu"] 		= data["sepatu"]
		get_node("%karakter/lulu").warna["sepatu"] 		= data["warna_sepatu"]
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
		get_node("%karakter/reno").warna["celana"] 		= data["warna_celana"]
		get_node("%karakter/reno").model["sepatu"] 		= data["sepatu"]
		get_node("%karakter/reno").warna["sepatu"] 		= data["warna_sepatu"]
		get_node("%karakter/reno").atur_warna()
		get_node("%karakter/reno").set_process(false)
		get_node("%karakter/reno").set_physics_process(false)
		match data["gender"]: # di dunia ini cuman ada 2 gender!
			'P': $karakter/panel/tab/tab_personalitas/pilih_gender.select(0); _ketika_mengubah_gender_karakter(0)
			'L': $karakter/panel/tab/tab_personalitas/pilih_gender.select(1); _ketika_mengubah_gender_karakter(1)
		
		koneksi = MODE_KONEKSI.CLIENT
		karakter = null
		dunia.hapus_map()
		dunia.hapus_instance_pemain()
		
		# hapus daftar pemain
		for d_pemain in $hud/daftar_pemain/panel/gulir/baris.get_children(): d_pemain.queue_free()
		
		$latar.tampilkan()
		_mainkan_musik_latar()

# kontrol
func _ketika_mulai_mengontrol_arah_pandangan(): _touchpad_disentuh = true
func _ketika_mengontrol_arah_pandangan(arah, _touchpad):
	if is_instance_valid(karakter) and !jeda: # ketika dalam permainan
		if _touchpad_disentuh:
			if _arah_sentuhan_touchpad.x == 0:
				karakter.arah_pandangan.x = 0
				_arah_sentuhan_touchpad.x = arah.x
			else:
				if arah.x < _arah_sentuhan_touchpad.x:
					karakter.arah_pandangan.x = arah.x - _arah_sentuhan_touchpad.x
					_arah_sentuhan_touchpad.x = arah.x
				else:
					karakter.arah_pandangan.x = arah.x - _arah_sentuhan_touchpad.x
					_arah_sentuhan_touchpad.x = arah.x
			
			if _arah_sentuhan_touchpad.y == 0:
				karakter.arah_pandangan.y = 0
				_arah_sentuhan_touchpad.y = arah.y
			else:
				if arah.y < _arah_sentuhan_touchpad.y:
					karakter.arah_pandangan.y = arah.y - _arah_sentuhan_touchpad.y
					_arah_sentuhan_touchpad.y = arah.y
				else:
					karakter.arah_pandangan.y = arah.y - _arah_sentuhan_touchpad.y
					_arah_sentuhan_touchpad.y = arah.y
			
			karakter.arah_pandangan.x =  karakter.arah_pandangan.x * 100
			karakter.arah_pandangan.x = ceil(karakter.arah_pandangan.x)
			karakter.arah_pandangan.y = -karakter.arah_pandangan.y * 100
			karakter.arah_pandangan.y = ceil(karakter.arah_pandangan.y)
		elif $pengamat/kamera/rotasi_vertikal/pandangan.current and $hud/daftar_properti_objek/DragPad.visible:
			# selama kontrol_sentuh visible, ini gak work karena _touchpad_disentuh : true, apalagi karena posisinya dibelakang kontrol_sentuh
			_arah_gestur_tampilan_objek = arah
		#Panku.notify("sentuh [harus false] : "+str(_touchpad_disentuh)+" -- arah_gestur_objek : "+str(_arah_gestur_tampilan_objek))
func _ketika_berhenti_mengontrol_arah_pandangan():
	_touchpad_disentuh = false
	if is_instance_valid(karakter): # ketika dalam permainan
		_arah_sentuhan_touchpad = Vector2.ZERO
		karakter.arah_pandangan = Vector2.ZERO
func _ketika_mengubah_mode_kontrol_gerak(mode):
	$kontrol_sentuh/kontrol_gerakan/analog.visible = false
	$"kontrol_sentuh/kontrol_gerakan/d-pad".visible = false
	match mode:
		0: $kontrol_sentuh/kontrol_gerakan/analog.visible = true;	Konfigurasi.mode_kontrol_gerak = "analog"
		1: $"kontrol_sentuh/kontrol_gerakan/d-pad".visible = true;	Konfigurasi.mode_kontrol_gerak = "dpad"
func _ketika_mengubah_jarak_render(jarak):
	if is_instance_valid(dunia) and dunia.get_node_or_null("lingkungan") != null:
		dunia.get_node("pemain/"+str(multiplayer.get_unique_id())+"/%pandangan").set("far", jarak)
func _ketika_mengontrol_arah_gerak(arah, _analog):
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
func _ketika_mulai_melompat():		Input.action_press("lompat")
func _ketika_berhenti_melompat():	Input.action_release("lompat")
func _aksi_1_tekan(): 				Input.action_press("aksi1_sentuh")
func _aksi_1_lepas(): 				Input.action_release("aksi1_sentuh");	$kontrol_sentuh/aksi_1.release_focus()
func _aksi_2_tekan(): 				Input.action_press("aksi2")
func _aksi_2_lepas(): 				Input.action_release("aksi2");			$kontrol_sentuh/aksi_2.release_focus()
func _ketika_mulai_berlari():		Input.action_press("berlari")
func _ketika_berhenti_berlari():	Input.action_release("berlari")

# UI
func _atur_persentase_memuat(nilai):
	$proses_memuat/panel_bawah/Panel/ProsesMemuat/animasi.get_animation("proses").track_set_key_value(0, 1, nilai)
	$proses_memuat/panel_bawah/Panel/ProsesMemuat/animasi.play("proses")
	$proses_memuat/panel_bawah/Panel/PersenMemuat.text = str(nilai)+"%"
func _tampilkan_permainan():
	$proses_memuat/panel_bawah/animasi.play_backwards("tampilkan")
	$latar.sembunyikan()
	_hentikan_musik_latar()
	$hud/kompas.parent = karakter
	$hud/kompas.set_physics_process(true)
	$mode_bermain.visible = true
	$mode_bermain/main.button_pressed = true
	$mode_bermain/edit.button_pressed = false
	$hud.visible = true
	$kontrol_sentuh.visible = Konfigurasi.mode_kontrol_sentuh
	$kontrol_sentuh/chat.visible = true
	$daftar_objek/tutup/TouchScreenButton.visible = Konfigurasi.mode_kontrol_sentuh
func _sembunyikan_antarmuka_permainan():
	$hud/kompas.set_physics_process(false)
	$hud/kompas.parent = null
	$hud.visible = false
	$mode_bermain.visible = false
	$kontrol_sentuh.visible = false
	$kontrol_sentuh/menu.visible = true
	$daftar_objek/tutup/TouchScreenButton.visible = false
	if $daftar_objek/Panel.anchor_top < 1: $daftar_objek/animasi.play("sembunyikan")
	jeda = false
func _tampilkan_pemutar_musik():
	if $pemutar_musik.visible: $pemutar_musik/animasi.play("sembunyikan")
	else: $pemutar_musik/animasi.play("tampilkan")
func _tampilkan_daftar_server():
	if $daftar_server.visible: _sembunyikan_daftar_server()
	else:
		if $pemutar_musik.visible: $pemutar_musik/animasi.play("sembunyikan")
		client.cari_server()
		if $karakter.visible: $karakter/animasi.play("tampilkan_server")
		else: $daftar_server/animasi.play("animasi_panel/tampilkan")
		$daftar_server/panel/panel_input/batal.grab_focus()
func _sembunyikan_daftar_server():
	client.hentikan_pencarian_server()
	_reset_daftar_server_lan()
	$daftar_server/animasi.play("animasi_panel/sembunyikan")
	$menu_utama/menu/Panel/gabung_server.grab_focus()
func _tambah_server_lan(ip, sys, nama, nama_map, jml_pemain, max_pemain):
	var server_lan = load("res://ui/server.tscn").instantiate()
	server_lan.name = ip.replace('.', '_');
	server_lan.atur(ip, sys, nama, nama_map, jml_pemain, max_pemain)
	server_lan.button_group = client.pilih_server
	$daftar_server/panel/daftar_lan/layout.add_child(server_lan)
func _pilih_server_lan(ip):
	$daftar_server/panel/panel_input/input_ip.text = ip
	$daftar_server/panel/panel_input/sambungkan.grab_focus()
func _hapus_server_lan(ip):
	$daftar_server/panel/daftar_lan/layout.get_node(ip.replace('.', '_')).queue_free()
func _reset_daftar_server_lan():
	var jumlah_koneksi_lan = $daftar_server/panel/daftar_lan/layout.get_child_count()
	for k in jumlah_koneksi_lan:
		$daftar_server/panel/daftar_lan/layout.get_child(jumlah_koneksi_lan - (k + 1)).queue_free()
func _pilih_tab_server_lan():
	if _posisi_tab_koneksi != "LAN":
		$daftar_server/panel/internet.button_pressed = false
		$daftar_server/panel/animasi_tab.play("lan")
		_posisi_tab_koneksi = "LAN"
func _pilih_tab_server_internet():
	if _posisi_tab_koneksi != "Internet":
		$daftar_server/panel/lan.button_pressed = false
		$daftar_server/panel/animasi_tab.play("internet")
		_posisi_tab_koneksi = "Internet"
func _sembunyikan_proses_koneksi():
	$proses_koneksi/animasi.play("sembunyikan")
	$proses_koneksi/panel/animasi.stop()
func _tampilkan_setelan_karakter():
	if $karakter.visible: _sembunyikan_setelan_karakter()
	else:
		if $pemutar_musik.visible: $pemutar_musik/animasi.play("sembunyikan")
		if $karakter/panel/tampilan/SubViewportContainer/SubViewport.get_node_or_null("pencahayaan_karakter") == null:
			$karakter/panel/tampilan/SubViewportContainer/SubViewport.add_child(
				load("res://pencahayaan_karakter.scn").instantiate()
			)
		$karakter/panel/tampilan/SubViewportContainer/SubViewport/lantai/CollisionShape3D.disabled = false
		if $karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter.visible == false:
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/karakter.visible = true
			match data["gender"]: # INFO : aktifkan visibilitas placeholder karakter berdasarkan data
				"P": get_node("%karakter/lulu").visible = true
				"L": get_node("%karakter/reno").visible = true
		if $daftar_server.visible:
			$daftar_server/animasi.play("tampilkan_karakter")
			client.hentikan_pencarian_server()
			_reset_daftar_server_lan()
		else: $karakter/animasi.play("tampilkan")
		$karakter/panel/batal.grab_focus()
func _sembunyikan_setelan_karakter():
	_pilih_tab_personalitas_karakter()
	$karakter/animasi.play("animasi_panel/sembunyikan")
	$menu_utama/menu/Panel/karakter.grab_focus()
func _ketika_ukuran_tampilan_karakter_diubah():
	$karakter/panel/tampilan/SubViewportContainer/SubViewport.size = $karakter/panel/tampilan.size
func _ketika_mengubah_arah_tampilan_karakter(arah, _touchpad):
	_arah_gestur_tampilan_karakter = arah
func _reset_pilihan_tab_karakter():
	$karakter/panel/pilih_tab_personalitas.button_pressed = false
	$karakter/panel/pilih_tab_wajah.button_pressed = false
	$karakter/panel/pilih_tab_rambut.button_pressed = false
	$karakter/panel/pilih_tab_baju.button_pressed = false
	$karakter/panel/pilih_tab_celana.button_pressed = false
	$karakter/panel/pilih_tab_sepatu.button_pressed = false
func _pilih_tab_personalitas_karakter():
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
func _pilih_tab_wajah_karakter():
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
		var tween_arah_pengamat = get_tree().create_tween()
		tween_arah_pengamat.tween_property(
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat,
			"rotation_degrees",
			Vector3(0, 40, 0),
			0.5
		)
		tween_arah_pengamat.play()
	elif $karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat.rotation_degrees.y < -60:
		var tween_arah_pengamat = get_tree().create_tween()
		tween_arah_pengamat.tween_property(
			$karakter/panel/tampilan/SubViewportContainer/SubViewport/pengamat,
			"rotation_degrees",
			Vector3(0, -40, 0),
			0.5
		)
		tween_arah_pengamat.play()
	# TODO : clamp putaran pengamat ke <= 60
func _pilih_tab_rambut_karakter():
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
func _pilih_tab_baju_karakter():
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
				0
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
func _pilih_tab_celana_karakter():
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
func _pilih_tab_sepatu_karakter():
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
func pilih_mode_bermain():
	if is_instance_valid(karakter) and !jeda:
		$mode_bermain/main.button_pressed = true
		$mode_bermain/edit.button_pressed = false
		karakter.peran = Permainan.PERAN_KARAKTER.Penjelajah
		Panku.notify("mode bermain")
		$mode_bermain/main.release_focus()
func pilih_mode_edit():
	if is_instance_valid(karakter) and !jeda:
		$mode_bermain/main.button_pressed = false
		$mode_bermain/edit.button_pressed = true
		karakter.peran = Permainan.PERAN_KARAKTER.Arsitek
		Panku.notify("mode edit")
		$mode_bermain/edit.release_focus()
func _pilih_tab_posisi_objek(): 
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
func _pilih_tab_rotasi_objek():
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
func _pilih_tab_skala_objek():
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
		$hud/daftar_properti_objek/panel/translasi_x.value = edit_objek.scale.x
		$hud/daftar_properti_objek/panel/translasi_y.min_value = 0.1
		$hud/daftar_properti_objek/panel/translasi_y.max_value = 100
		$hud/daftar_properti_objek/panel/translasi_y.value = edit_objek.scale.y
		$hud/daftar_properti_objek/panel/translasi_z.min_value = 0.1
		$hud/daftar_properti_objek/panel/translasi_z.max_value = 100
		$hud/daftar_properti_objek/panel/translasi_z.value = edit_objek.scale.z
		$hud/daftar_properti_objek/panel/translasi_x.editable = true
		$hud/daftar_properti_objek/panel/translasi_y.editable = true
		$hud/daftar_properti_objek/panel/translasi_z.editable = true
func _tampilkan_daftar_objek():
	if $daftar_objek/Panel.anchor_top > 0: $daftar_objek/animasi.play("tampilkan")
	karakter._atur_kendali(false)
	karakter.kontrol = true
	memasang_objek = true
func _tutup_daftar_objek(paksa = false):
	# kalau paksa berarti kendali pemain gak dikembaliin
	$daftar_objek/animasi.play("sembunyikan")
	if !paksa: karakter._atur_kendali(true)
	memasang_objek = false
func _tambah_translasi_x_objek():
	$hud/daftar_properti_objek/panel/translasi_x.value += $hud/daftar_properti_objek/panel/translasi_x.step
	#_ketika_translasi_x_objek_diubah($hud/daftar_properti_objek/panel/translasi_x.value)
func _kurang_translasi_x_objek():
	$hud/daftar_properti_objek/panel/translasi_x.value -= $hud/daftar_properti_objek/panel/translasi_x.step
	#_ketika_translasi_x_objek_diubah($hud/daftar_properti_objek/panel/translasi_x.value)
func _tambah_translasi_y_objek():
	$hud/daftar_properti_objek/panel/translasi_y.value += $hud/daftar_properti_objek/panel/translasi_y.step
	#_ketika_translasi_y_objek_diubah($hud/daftar_properti_objek/panel/translasi_y.value)
func _kurang_translasi_y_objek():
	$hud/daftar_properti_objek/panel/translasi_y.value -= $hud/daftar_properti_objek/panel/translasi_y.step
	#_ketika_translasi_y_objek_diubah($hud/daftar_properti_objek/panel/translasi_y.value)
func _tambah_translasi_z_objek():
	$hud/daftar_properti_objek/panel/translasi_z.value += $hud/daftar_properti_objek/panel/translasi_z.step
	#_ketika_translasi_z_objek_diubah($hud/daftar_properti_objek/panel/translasi_z.value)
func _kurang_translasi_z_objek():
	$hud/daftar_properti_objek/panel/translasi_z.value -= $hud/daftar_properti_objek/panel/translasi_z.step
	#_ketika_translasi_z_objek_diubah($hud/daftar_properti_objek/panel/translasi_z.value)
func _ketika_translasi_x_objek_diubah(nilai):
	if $hud/daftar_properti_objek/panel/translasi_x.editable:
		#Panku.notify("ceritakan padanya~")
		if edit_objek != null:
			await get_tree().create_timer(0.05).timeout
			if $hud/daftar_properti_objek/panel/pilih_tab_posisi.button_pressed:
				server.atur_properti_objek(edit_objek.get_path(), "global_transform:origin:x", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_rotasi.button_pressed:
				server.atur_properti_objek(edit_objek.get_path(), "rotation_degrees:x", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_skala.button_pressed:
				server.atur_properti_objek(edit_objek.get_path(), "scale:x", nilai)
func _ketika_translasi_y_objek_diubah(nilai):
	if $hud/daftar_properti_objek/panel/translasi_y.editable:
		if edit_objek != null:
			await get_tree().create_timer(0.05).timeout
			if $hud/daftar_properti_objek/panel/pilih_tab_posisi.button_pressed:
				server.atur_properti_objek(edit_objek.get_path(), "global_transform:origin:y", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_rotasi.button_pressed:
				server.atur_properti_objek(edit_objek.get_path(), "rotation_degrees:y", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_skala.button_pressed:
				server.atur_properti_objek(edit_objek.get_path(), "scale:y", nilai)
func _ketika_translasi_z_objek_diubah(nilai):
	if $hud/daftar_properti_objek/panel/translasi_z.editable:
		if edit_objek != null:
			await get_tree().create_timer(0.05).timeout
			if $hud/daftar_properti_objek/panel/pilih_tab_posisi.button_pressed:
				server.atur_properti_objek(edit_objek.get_path(), "global_transform:origin:z", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_rotasi.button_pressed:
				server.atur_properti_objek(edit_objek.get_path(), "rotation_degrees:z", nilai)
			elif $hud/daftar_properti_objek/panel/pilih_tab_skala.button_pressed:
				server.atur_properti_objek(edit_objek.get_path(), "scale:z", nilai)
func _tampilkan_popup_informasi(teks_informasi, fokus_setelah):
	$popup_informasi.target_fokus_setelah = fokus_setelah
	$popup_informasi/panel/teks.text = teks_informasi
	$popup_informasi/animasi.play_backwards("tutup")
	$popup_informasi/panel/tutup.grab_focus()
func _tutup_popup_informasi():
	$popup_informasi/animasi.play("tutup")
	$popup_informasi/panel/teks.text = ""+str(randf())
	$popup_informasi.target_fokus_setelah.grab_focus()
func _tampilkan_popup_konfirmasi(tombol_penampil : Button, fungsi : Callable, teks):
	$popup_konfirmasi.penampil = tombol_penampil
	$popup_konfirmasi.fungsi = fungsi
	$popup_konfirmasi/panel/teks.text = teks
	$popup_konfirmasi/animasi.play("tampilkan")
	$popup_konfirmasi/panel/batal.grab_focus()
func _ketika_konfirmasi_popup_konfirmasi():
	$popup_konfirmasi/animasi.play_backwards("tampilkan")
	$popup_konfirmasi.fungsi.call()
	$popup_konfirmasi.penampil.grab_focus()
func _tutup_popup_konfirmasi():
	$popup_konfirmasi/animasi.play("tutup")
	$popup_konfirmasi.penampil.grab_focus()
func _mainkan_musik_latar():
#	if $pemutar_musik/AudioStreamPlayer.stream == null:
#		var musik = load("res://audio/soundtrack/Holding Hands.mp3")
#		if musik != null:
#			$pemutar_musik/AudioStreamPlayer.stream = musik
#			$pemutar_musik/AudioStreamPlayer.play()
#			$pemutar_musik/judul.text = "Holding Hands"
#			$pemutar_musik/artis.text = "Couple N"
#			$pemutar_musik/posisi_durasi.max_value = $pemutar_musik/AudioStreamPlayer.stream.get_length()
#	else:
#		$pemutar_musik/AudioStreamPlayer.play()
#		$pemutar_musik/posisi_durasi.max_value = $pemutar_musik/AudioStreamPlayer.stream.get_length()
	pass
func _ketika_musik_latar_selesai_dimainkan():
	await get_tree().create_timer(10.0).timeout
	_mainkan_musik_latar()
func _hentikan_musik_latar():
	$pemutar_musik/AudioStreamPlayer.stop()
	$pemutar_musik/AudioStreamPlayer.stream = null
func _tambah_daftar_pemain(id_pemain, data_pemain):
	var pemain = load("res://ui/pemain.tscn").instantiate()
	# INFO : tambahkan info pemain ke daftar pemain
	#print("just a little more~")
	$hud/daftar_pemain/panel/gulir/baris.add_child(pemain)
	pemain.id		= data_pemain["id_sys"]
	pemain.sistem	= data_pemain["sistem"]
	pemain.nama		= data_pemain["nama"]
	pemain.karakter	= data_pemain["gender"]
	pemain.name = str(id_pemain)
func _hapus_daftar_pemain(id_pemain):
	var tmp_daftar = $hud/daftar_pemain/panel/gulir/baris.get_node(str(id_pemain))
	$hud/daftar_pemain/panel/gulir/baris.remove_child(tmp_daftar)
	tmp_daftar.queue_free()
func _tampilkan_setelan_permainan():
	Panku.gd_exprenv.execute("setelan.buka_setelan_permainan()")
func _tampilkan_input_pesan():
	$kontrol_sentuh/chat.release_focus()
	if pesan:
		$hud/pesan/input_pesan.release_focus()
		$hud/daftar_pesan/animasi.play("sembunyikan")
		$hud/pesan/animasi.play("sembunyikan")
		if $daftar_objek/Panel.anchor_top < 1 or edit_objek != null: pass # jangan tangkap mouse ketika menutup input pesan pada saat membuat/mengedit objek
		else:
			$kontrol_sentuh/mic.visible = true
			$kontrol_sentuh/lari.visible = true
			karakter._atur_kendali(true)
		pesan = false
	else:
		$hud/daftar_pesan/animasi.play("tampilkan")
		$hud/pesan/animasi.play("tampilkan")
		$hud/pesan/input_pesan.grab_focus()  
		if $daftar_objek/Panel.anchor_top < 1 or edit_objek != null: pass # jangan ubah kendali pemain ketika membuka input pesan pada saat membuat/mengedit objek
		else:
			$kontrol_sentuh/mic.visible = false
			$kontrol_sentuh/lari.visible = false
			karakter._atur_kendali(false)
		pesan = true
func _tampilkan_pesan(teks : String):
	$hud/daftar_pesan/animasi.play("tampilkan")
	$hud/daftar_pesan.append_text("\n"+teks)
	if !pesan:
		# 15 karakter = 3 detik
		# jadi 5 karakter = 1 detik
		# dan 1 karakter = 0.2 detik
		_timer_tampilkan_pesan.wait_time = 0.2 * teks.length()
		_timer_tampilkan_pesan.start()
func _sembunyikan_pesan():
	if !pesan:
		$hud/daftar_pesan/animasi.play("sembunyikan")
		_timer_tampilkan_pesan.stop()
func _tampilkan_panel_informasi():
	if $pemutar_musik.visible: $pemutar_musik/animasi.play("sembunyikan")
	if $daftar_server.visible: _sembunyikan_daftar_server()
	if $karakter.visible: _sembunyikan_setelan_karakter()
	await get_tree().create_timer(0.4).timeout
	$menu_utama/animasi.play("sembunyikan")
	$informasi/animasi.play("tampilkan")
func _sembunyikan_panel_informasi():
	$informasi/animasi.play("tutup")
	$menu_utama/animasi.play("tampilkan")
	$menu_utama/menu/Panel/buat_server.grab_focus()
func _ketika_menekan_link_informasi(tautan):
	Panku.notify(tautan)
func lepaskan_kursor_mouse(): Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

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

# menu
func _jeda():
	if is_instance_valid(karakter) and karakter.has_method("_atur_kendali"):
		if $pengamat/kamera/rotasi_vertikal/pandangan.current: pass
		else:
			if memasang_objek: _tutup_daftar_objek(true)
			karakter._atur_kendali(false)
		$kontrol_sentuh/menu.visible = false
		$kontrol_sentuh/chat.visible = false
		$menu_jeda/menu/animasi.play("tampilkan")
		$menu_jeda/menu/kontrol/Panel/lanjutkan.grab_focus()
		jeda = true
func _lanjutkan():
	if is_instance_valid(karakter) and karakter.has_method("_atur_kendali"):
		if is_instance_valid(edit_objek): pass
		else: karakter._atur_kendali(true)
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
	elif $proses_koneksi.visible:
		client.putuskan_server()
		$proses_koneksi/animasi.play("sembunyikan")
	elif $daftar_server.visible:
		_sembunyikan_daftar_server()
	elif $karakter.visible:
		_sembunyikan_setelan_karakter()
	elif !is_instance_valid(karakter):
		_keluar()
func _putuskan():
	putuskan_server()
func _keluar():
	_tampilkan_popup_konfirmasi($menu_utama/keluar, Callable(get_tree(), "quit"), "%keluar%")

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

# bantuan pada console
const _HELP_cek_koneksi_server	:= "Cek status koneksi dengan server"
const _HELP_putuskan_server 	:= "Hentikan/Putuskan server [fungsi ini dipanggil secara otomatis!] * memanggilnya secara manual akan membiarkan kursor mouse dalam kondisi capture"
const _HELP_PERAN_KARAKTER		:= "Tipe-tipe peran yang dapat diperankan karakter/pemain" # gak work!
