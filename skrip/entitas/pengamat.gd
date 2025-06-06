extends Node3D

@export var kontrol : bool = false
@export var mode_kontrol : int = 3
@export var mode_kendaraan : bool = false
@export var posisi_z_kustom : float = 0.15		# posisi z untuk mode kendaraan | hanya digunakan pada mode_kontrol 2 | dapat diatur ulang dengan atur_ulang_posisi_z_kustom()

var gerakan : Vector2
var _gerakan : Vector2
var rotasi : Vector3
var fokus_pandangan_belakang : Node3D			# node yang difokus pada mode_kontrol 3 | hanya digunakan pada mode kendaraan
var posisi_pandangan_belakang : float = 1.5:	# jarak posisi pandangan z pada mode_kontrol 3 | harus diatur sebelum memanggil atur_mode_kendaraan() | dapat diatur ulang dengan atur_ulang_posisi_pandangan_belakang()
	set(nilai):
		if mode_kontrol == 3:
			var tween_pandangan_belakang : Tween = get_tree().create_tween()
			tween_pandangan_belakang.tween_property($kamera/rotasi_vertikal/pandangan, "position:z", -nilai, 0.2)
			tween_pandangan_belakang.play()
		posisi_pandangan_belakang = nilai
var putaranMinVertikalPandangan : float = -85.0
var putaranMinVertikalPandanganKendaraan : float = -45.0
var putaranMaxVertikalPandangan : float = 90.0
var posisiAwalVertikalPandangan : float

var _karakter : Node

func _ready() -> void:
	if get_parent() is Karakter:
		_karakter = get_parent();
		get_node("%pandangan").set("far", Konfigurasi.jarak_render);
		get_node("%pandangan").set("fov", Konfigurasi.sudut_pandangan);
		posisiAwalVertikalPandangan = position.y
		$kamera/transisi.modulate = Color(1, 1, 1, 0)
	else: _karakter = $posisi_mata

func _process(delta : float) -> void:
	if kontrol:
		if _karakter.get("_input_arah_pandangan") != null: gerakan = _karakter._input_arah_pandangan
		rotasi = Vector3(gerakan.y, gerakan.x, 0) * Konfigurasi.sensitivitas_pandangan * delta
		
		if mode_kendaraan and _karakter.gestur == "duduk":
			if gerakan == Vector2.ZERO and (_karakter.arah.x != 0 or _karakter.arah.z != 0):
				if mode_kontrol == 2:
					$kamera/rotasi_vertikal.rotation.y = lerp_angle($kamera/rotasi_vertikal.rotation.y, deg_to_rad(0.0), 5.0 * delta)
				# 08/05/25 :: jangan rotasi arah x dan z mode pandangan 3 ketika menaiki kendaraan 
				elif mode_kontrol == 3:
					rotation.y = lerp_angle(rotation.y, deg_to_rad(0.0), 0.5 * delta)
			if mode_kontrol == 3:
				global_rotation.x = lerp_angle(global_rotation.x, deg_to_rad(0.0), 7.5 * delta)
				global_rotation.z = lerp_angle(global_rotation.z, deg_to_rad(0.0), 7.5 * delta)
		
		if gerakan != _gerakan:
			match mode_kontrol:
				1:
					get_node("%pandangan").rotation_degrees.x -= rotasi.x
					get_node("%pandangan").rotation_degrees.x = clamp(get_node("%pandangan").rotation_degrees.x, putaranMinVertikalPandangan, putaranMaxVertikalPandangan)
					get_node("%target").rotation_degrees.x = -get_node("%pandangan").rotation_degrees.x
					_karakter.rotation_degrees.y -= rotasi.y
					gerakan = Vector2.ZERO
					if _karakter.get("_input_arah_pandangan") != null:
						_karakter._input_arah_pandangan = Vector2.ZERO
					if _karakter.get("arah_pandangan") != null:
						if get_node("%pandangan").rotation_degrees.x > 0:
							_karakter.arah_pandangan.y = get_node("%pandangan").rotation_degrees.x / putaranMaxVertikalPandangan
						elif get_node("%pandangan").rotation_degrees.x < 0:
							var arah_pandangan : float = -get_node("%pandangan").rotation_degrees.x / putaranMinVertikalPandangan
							var persentase_arah : float = abs(arah_pandangan)
							#var perbedaan_posisi_y_akhir = 0.064 * persentase_arah
							var perbedaan_posisi_z_akhir : float = 0.237 * persentase_arah
							#position.y = posisiAwalVertikalPandangan - perbedaan_posisi_y_akhir # gak usah dipake karena bakalan offset ketika pemain jongkok
							get_node("%pandangan").position.z = 0 + perbedaan_posisi_z_akhir
							_karakter.arah_pandangan.y = arah_pandangan
				2:
					get_node("%pandangan").rotation_degrees.x -= rotasi.x
					get_node("%pandangan").rotation_degrees.x = clamp(get_node("%pandangan").rotation_degrees.x, putaranMinVertikalPandanganKendaraan, putaranMaxVertikalPandangan)
					get_node("%target").rotation_degrees.x = -get_node("%pandangan").rotation_degrees.x
					if _karakter.gestur == "berdiri" and (_karakter.arah.x != 0 or _karakter.arah.z != 0):
						_karakter.rotation.y = lerp_angle(_karakter.rotation.y, $kamera/rotasi_vertikal.global_rotation.y, 0.4)
						$kamera/rotasi_vertikal.rotation.y = lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(0.0), 0.4)
						_karakter.rotation_degrees.y -= rotasi.y
					else:
						$kamera/rotasi_vertikal.rotation_degrees.y -= rotasi.y
						$kamera/rotasi_vertikal.rotation_degrees.y = clamp($kamera/rotasi_vertikal.rotation_degrees.y, -70, 70)
					gerakan = Vector2.ZERO
					if _karakter.get("_input_arah_pandangan") != null: _karakter._input_arah_pandangan = Vector2.ZERO
					if _karakter.get("arah_pandangan") != null:
						# arah pandangan horizontal karakter y ==> (x)
						if $kamera/rotasi_vertikal.rotation_degrees.y > 0:
							_karakter.arah_pandangan.x = -$kamera/rotasi_vertikal.rotation_degrees.y / 70
						elif $kamera/rotasi_vertikal.rotation_degrees.y < 0:
							_karakter.arah_pandangan.x = $kamera/rotasi_vertikal.rotation_degrees.y / -70
						else:
							_karakter.arah_pandangan.x = 0
						# arah pandangan vertikal karakter x ==> (y)
						if get_node("%pandangan").rotation_degrees.x > 0:
							var persentase_arah : float = -get_node("%pandangan").rotation_degrees.x / putaranMaxVertikalPandangan
							_karakter.arah_pandangan.y = persentase_arah
							get_node("%pandangan").position.z = posisi_z_kustom * absf(persentase_arah)
						elif get_node("%pandangan").rotation_degrees.x < 0:
							var persentase_arah : float = get_node("%pandangan").rotation_degrees.x / putaranMinVertikalPandanganKendaraan
							_karakter.arah_pandangan.y = persentase_arah
							get_node("%pandangan").position.z = posisi_z_kustom * persentase_arah
						else:
							_karakter.arah_pandangan.y = 0
				3:
					$kamera/rotasi_vertikal.rotation_degrees.x += rotasi.x
					$kamera/rotasi_vertikal.rotation_degrees.x = clamp($kamera/rotasi_vertikal.rotation_degrees.x, -65, putaranMaxVertikalPandangan)
					get_node("%target").rotation_degrees.x = 0
					if (_karakter.arah.x != 0 or (_karakter.arah.z != 0 and _karakter.is_on_floor())) and _karakter.gestur == "berdiri":
						_karakter.rotation.y = lerp_angle(_karakter.rotation.y, global_rotation.y, 0.4)
						rotation.y = lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(0.0), 0.4)
						_karakter.rotation_degrees.y -= rotasi.y
					else: rotation_degrees.y -= rotasi.y
					if rotation_degrees.y < -360:	rotation_degrees.y += 360
					if rotation_degrees.y > 360:	rotation_degrees.y -= 360
					if rotation_degrees.y <= -270:	rotation_degrees.y += 90 * 4
					if rotation_degrees.y >= 270:	rotation_degrees.y -= 90 * 4
					gerakan = Vector2.ZERO
					if _karakter.get("_input_arah_pandangan") != null: _karakter._input_arah_pandangan = Vector2.ZERO
					if _karakter.get("arah_pandangan") != null: _karakter.arah_pandangan = Vector2.ZERO # TODO : arah x
			_gerakan = gerakan
	
	# atur posisi pengamat
	if _karakter._ragdoll:
		global_position = _karakter.get_node("%pinggang").global_position
	elif mode_kendaraan and fokus_pandangan_belakang != null and mode_kontrol == 3:
		position = fokus_pandangan_belakang.position
	else:
		$kamera.position.x = 0
		position.y 			= get_node("%mata_kiri").position.y
		$kamera.position.z	= get_node("%mata_kiri").position.z * 0.5
		_karakter.get_node("fisik_kepala").rotation		= _karakter.get_node("%mata_kiri").rotation
		_karakter.get_node("fisik_kepala").position.y	= _karakter.get_node("%mata_kiri").position.y
		_karakter.get_node("fisik_kepala").position.z	= _karakter.get_node("%mata_kiri").position.z

func aktifkan(nilai := true, vr := false) -> void:
	if vr:	pass
	else:
		if get_node("%pandangan").current != nilai:
			get_node("%pandangan").current = nilai
		if get_node("%target").enabled != nilai:
			get_node("%target").enabled = nilai
	
	if 	nilai:	_karakter.get_node("nama").visible = false
	else:		_karakter.get_node("nama").visible = true

func atur_mode(nilai : int) -> void:
	get_node("%pandangan").set("fov", Konfigurasi.sudut_pandangan); # reset zoom
	var transisi : bool = false if (nilai == 2 and mode_kontrol == 1) or (nilai == 1 and mode_kontrol == 2) else true
	if mode_kontrol == 2: mode_kontrol = 1
	if mode_kontrol == 1 and nilai == 2: mode_kontrol = 2 # naik kendaraan / mulai duduk
	# 07/05/25 :: sembunyikan tombol zoom pada mode pandangan 3
	if nilai == 3:	server.permainan._sembunyikan_tombol_zoom()
	else:			server.permainan._tampilkan_tombol_zoom()
	var ubah : bool = (mode_kontrol != nilai)
	mode_kontrol = 0 # nonaktifkan kontrol
	atur_ulang_arah_pandangan()
	if !ubah: mode_kontrol = nilai; return
	if transisi:
		if _karakter.kontrol:	$kamera/transisi.visible = true
		else:					$kamera/transisi.visible = false
		match nilai:
			1:	$animasi.get_animation("pandangan_utama").track_set_key_value(2, 2, 1); $animasi.play("pandangan_utama")
			2:	$animasi.get_animation("pandangan_utama").track_set_key_value(2, 2, 2); $animasi.play("pandangan_utama")
			3:
				$animasi.get_animation("pandangan_utama").track_set_key_value(0, 0,		Vector3(0, 0, -posisi_pandangan_belakang));
				$animasi.get_animation("pandangan_belakang").track_set_key_value(0, 1,	Vector3(0, 0, -posisi_pandangan_belakang));
				$animasi.play("pandangan_belakang") # TODO : Clipped Camera
func ubah_mode() -> void:
	if mode_kendaraan:
		match mode_kontrol:
			2: atur_mode(3)
			3: atur_mode(2)
	else:
		match mode_kontrol:
			1: atur_mode(3)
			3: atur_mode(1)
func atur_mode_kendaraan(mode : bool) -> void:
	if mode and mode_kontrol == 1:		atur_mode(2)
	elif !mode and mode_kontrol == 2:	atur_mode(1)
	atur_ulang_arah_pandangan()
	mode_kendaraan = mode
func atur_ulang_arah_pandangan() -> void:
	var tween_pandangan_1a : Tween = get_tree().create_tween()
	var tween_pandangan_2a : Tween = get_tree().create_tween()
	var tween_pandangan_3a : Tween = get_tree().create_tween()
	var tween_pandangan_3b : Tween = get_tree().create_tween()
	var tween_pandangan_3c : Tween = get_tree().create_tween()
	var tween_pandangan_3d : Tween = get_tree().create_tween()
	tween_pandangan_1a.tween_property($kamera/rotasi_vertikal/pandangan, "rotation_degrees:x", 0, 0.2)	# reset pandangan 1
	tween_pandangan_2a.tween_property($kamera/rotasi_vertikal, "rotation_degrees:y", 0, 0.2)			# reset pandangan 2
	tween_pandangan_3a.tween_property($kamera/rotasi_vertikal, "rotation_degrees:x", 0, 0.25)			# reset pandangan 3
	tween_pandangan_3b.tween_property(self, "rotation_degrees:y", 0, 0.25)								# reset pandangan 3
	tween_pandangan_3c.tween_property(self, "rotation_degrees:x", 0, 0.2)								# reset pandangan 3 kendaraan
	tween_pandangan_3d.tween_property(self, "rotation_degrees:z", 0, 0.2)								# reset pandangan 3 kendaraan
	tween_pandangan_1a.play()
	tween_pandangan_2a.play()
	tween_pandangan_3a.play()
	tween_pandangan_3b.play()
	tween_pandangan_3c.play()
	tween_pandangan_3d.play()
	if mode_kontrol == 2:
		var tween_pandangan_1b : Tween = get_tree().create_tween()
		tween_pandangan_1b.tween_property($kamera/rotasi_vertikal/pandangan, "position:z", 0, 0.2)		# reset pandangan 2
		tween_pandangan_1b.play()
	if _karakter.get("arah_pandangan") != null:
		_karakter.arah_pandangan.x = 0
		_karakter.arah_pandangan.y = 0
func atur_ulang_posisi_z_kustom() -> void:
	posisi_z_kustom = 0.15
func atur_ulang_posisi_pandangan_belakang() -> void:
	posisi_pandangan_belakang = 1.5

func fungsikan(nilai : bool) -> void:
	if nilai: 	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;	#ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", false)#; Panku.notify("set : false = hasil : "+str(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch")))
	else: 		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;	#ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", true)# biarpun berhasil di-set, ketika runtime gak ngaruh
	kontrol = nilai
