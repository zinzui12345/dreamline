extends Node3D

@export var kontrol : bool = false
@export var mode_kontrol : int = 3
var gerakan : Vector2
var _gerakan : Vector2
var rotasi : Vector3
var putaranMinVertikalPandangan : float = -85.0
var putaranMaxVertikalPandangan : float = 90.0
var posisiAwalVertikalPandangan : float

var _karakter : Node

func _ready() -> void:
	if get_parent() is Karakter:
		_karakter = get_parent();
		get_node("%pandangan").set("far", Konfigurasi.jarak_render);
		posisiAwalVertikalPandangan = position.y
		$kamera/transisi.modulate = Color(1, 1, 1, 0)
	else: _karakter = $posisi_mata

func _process(delta : float) -> void:
	if kontrol:
		if _karakter.get("_input_arah_pandangan") != null: gerakan = _karakter._input_arah_pandangan
		rotasi = Vector3(gerakan.y, gerakan.x, 0) * Konfigurasi.sensitivitasPandangan * delta
		
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
					get_node("%pandangan").rotation_degrees.x = clamp(get_node("%pandangan").rotation_degrees.x, -38, putaranMaxVertikalPandangan)
					get_node("%target").rotation_degrees.x = -get_node("%pandangan").rotation_degrees.x
					if _karakter.gestur == "berdiri" and (_karakter.arah.x != 0 or _karakter.arah.z != 0):
						_karakter.rotation.y = lerp_angle(_karakter.rotation.y, $kamera/rotasi_vertikal.global_rotation.y, 0.4)
						$kamera/rotasi_vertikal.rotation.y = lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(0.0), 0.4)
						_karakter.rotation_degrees.y -= rotasi.y
					elif _karakter.arah.z == 2:
						$kamera/rotasi_vertikal.rotation.y = lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(0.0), 0.005 * delta)
					else:
						$kamera/rotasi_vertikal.rotation_degrees.y -= rotasi.y
						$kamera/rotasi_vertikal.rotation_degrees.y = clamp($kamera/rotasi_vertikal.rotation_degrees.y, -70, 70)
					gerakan = Vector2.ZERO
					if _karakter.get("_input_arah_pandangan") != null: _karakter._input_arah_pandangan = Vector2.ZERO
					if _karakter.get("arah_pandangan") != null:
						if $kamera/rotasi_vertikal.rotation_degrees.y > 0:
							_karakter.arah_pandangan.x = -$kamera/rotasi_vertikal.rotation_degrees.y / 70
						elif $kamera/rotasi_vertikal.rotation_degrees.y < 0:
							_karakter.arah_pandangan.x = $kamera/rotasi_vertikal.rotation_degrees.y / -70
						else:
							_karakter.arah_pandangan.x = 0
				3:
					$kamera/rotasi_vertikal.rotation_degrees.x += rotasi.x
					$kamera/rotasi_vertikal.rotation_degrees.x = clamp($kamera/rotasi_vertikal.rotation_degrees.x, -65, putaranMaxVertikalPandangan)
					get_node("%target").rotation_degrees.x = 0
					if (_karakter.arah.x != 0 or (_karakter.arah.z != 0 and _karakter.is_on_floor())) and _karakter.get_node("pose").active:
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
	if mode_kontrol == 2: mode_kontrol = 1
	if mode_kontrol == 1 and nilai == 2: mode_kontrol = 2 # naik kendaraan / mulai duduk
	var ubah : bool = (mode_kontrol != nilai)
	mode_kontrol = 0 # nonaktifkan kontrol
	var tween_pandangan_1a : Tween = get_tree().create_tween()
	var tween_pandangan_2a : Tween = get_tree().create_tween()
	var tween_pandangan_3a : Tween = get_tree().create_tween()
	var tween_pandangan_3b : Tween = get_tree().create_tween()
	tween_pandangan_1a.tween_property($kamera/rotasi_vertikal/pandangan, "rotation_degrees:x", 0, 0.2)	# reset pandangan 1
	tween_pandangan_2a.tween_property($kamera/rotasi_vertikal, "rotation_degrees:y", 0, 0.2)			# reset pandangan 2
	tween_pandangan_3a.tween_property($kamera/rotasi_vertikal, "rotation_degrees:x", 0, 0.25)			# reset pandangan 3
	tween_pandangan_3b.tween_property(self, "rotation_degrees:y", 0, 0.25)								# reset pandangan 3
	tween_pandangan_1a.play()
	tween_pandangan_2a.play()
	tween_pandangan_3a.play()
	tween_pandangan_3b.play()
	if !ubah: mode_kontrol = nilai; return
	if _karakter.kontrol:	$kamera/transisi.visible = true
	else:					$kamera/transisi.visible = false
	match nilai:
		1:	$animasi.get_animation("pandangan_utama").track_set_key_value(2, 2, 1); $animasi.play("pandangan_utama")
		2:	$animasi.get_animation("pandangan_utama").track_set_key_value(2, 2, 2); $animasi.play("pandangan_utama")
		3:	$animasi.play("pandangan_belakang") # TODO : Clipped Camera
func ubah_mode() -> void:
	match mode_kontrol:
		1: atur_mode(3)
		3: atur_mode(1)

func fungsikan(nilai : bool) -> void:
	if nilai: 	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED;	#ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", false)#; Panku.notify("set : false = hasil : "+str(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch")))
	else: 		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE;	#ProjectSettings.set_setting("input_devices/pointing/emulate_mouse_from_touch", true)# biarpun berhasil di-set, ketika runtime gak ngaruh
	kontrol = nilai
