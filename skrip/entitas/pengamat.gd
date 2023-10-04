extends Node3D

@export var kontrol = false
@export var mode_kontrol = 1
var gerakan : Vector2
var rotasi : Vector3
var putaranMinVertikalPandangan : float = -85.0
var putaranMaxVertikalPandangan : float = 90.0

var _karakter

func  _ready():
	if get_parent() is Karakter: _karakter = get_parent()
	else: _karakter = $posisi_mata

func _input(_event):
	if kontrol:
		if Input.is_action_just_pressed("mode_pandangan"): ubah_mode() # HACK : ini mending dipindah ke pemain.gd!

func _process(delta):
	if kontrol:
		if _karakter.get("arah_pandangan") != null: gerakan = _karakter.arah_pandangan
		rotasi = Vector3(gerakan.y, gerakan.x, 0) * Konfigurasi.sensitivitasPandangan * delta
		
		# pindah ke karakter.gd process()
		#if _karakter.get_node_or_null("model/Root/Skeleton3D/dada") != null:
		#	global_position.y = _karakter.get_node_or_null("model/Root/Skeleton3D/dada").global_position.y
		
		match mode_kontrol:
			1:
				get_node("%pandangan").rotation_degrees.x -= rotasi.x
				get_node("%pandangan").rotation_degrees.x = clamp(get_node("%pandangan").rotation_degrees.x, putaranMinVertikalPandangan, putaranMaxVertikalPandangan)
				get_node("%target").rotation_degrees.x = -get_node("%pandangan").rotation_degrees.x
				_karakter.rotation_degrees.y -= rotasi.y
				gerakan = Vector2.ZERO
				if _karakter.get("arah_pandangan") != null: _karakter.arah_pandangan = Vector2.ZERO
				if _karakter.get("arah_p_pandangan") != null:
					# FIXME : leher terlihat ketika delay
					if get_node("%pandangan").rotation_degrees.x > 0:
						_karakter.arah_p_pandangan.y = get_node("%pandangan").rotation_degrees.x / putaranMaxVertikalPandangan
					elif get_node("%pandangan").rotation_degrees.x < 0:
						_karakter.arah_p_pandangan.y = -get_node("%pandangan").rotation_degrees.x / putaranMinVertikalPandangan
			3:
				$kamera/rotasi_vertikal.rotation_degrees.x += rotasi.x
				$kamera/rotasi_vertikal.rotation_degrees.x = clamp($kamera/rotasi_vertikal.rotation_degrees.x, -65, putaranMaxVertikalPandangan)
				get_node("%target").rotation_degrees.x = 0
				if _karakter.arah.x != 0 or (_karakter.arah.z != 0 and _karakter.is_on_floor()):
					_karakter.rotation.y = lerp_angle(_karakter.rotation.y, global_rotation.y, 0.4)
					rotation.y = lerp_angle(deg_to_rad(rotation_degrees.y), deg_to_rad(0.0), 0.4)
					_karakter.rotation_degrees.y -= rotasi.y
				else: rotation_degrees.y -= rotasi.y
				gerakan = Vector2.ZERO
				if _karakter.get("arah_pandangan") != null: _karakter.arah_pandangan = Vector2.ZERO
				if _karakter.get("arah_p_pandangan") != null: _karakter.arah_p_pandangan = Vector2.ZERO # TODO : arah x

func aktifkan(nilai = true, vr = false):
	if vr:	pass
	else:
		get_node("%pandangan").current = nilai
		get_node("%target").enabled = nilai
	
	if nilai:
		_karakter.get_node("nama").visible = false
		#for md in _karakter.get_node("model/Root/Skeleton3D").get_child_count():
		#	if _karakter.get_node("model/Root/Skeleton3D").get_child(md) is MeshInstance3D:
		#		_karakter.get_node("model/Root/Skeleton3D").get_child(md).set_layer_mask_value(1, false)
		#		_karakter.get_node("model/Root/Skeleton3D").get_child(md).set_layer_mask_value(2, true)
	else:
		_karakter.get_node("nama").visible = true
		#for md in _karakter.get_node("model/Root/Skeleton3D").get_child_count():
		#	if _karakter.get_node("model/Root/Skeleton3D").get_child(md) is MeshInstance3D:
		#		_karakter.get_node("model/Root/Skeleton3D").get_child(md).set_layer_mask_value(1, true)
		#		_karakter.get_node("model/Root/Skeleton3D").get_child(md).set_layer_mask_value(2, false)

func atur_mode(nilai):
	mode_kontrol = 0 # nonaktifkan kontrol
	var tween_pandangan_1 = get_tree().create_tween()
	var tween_pandangan_3a = get_tree().create_tween()
	var tween_pandangan_3b = get_tree().create_tween()
	tween_pandangan_1.tween_property($kamera/rotasi_vertikal/pandangan, "rotation_degrees:x", 0, 0.4)	# reset pandangan 1
	tween_pandangan_3a.tween_property($kamera/rotasi_vertikal, "rotation_degrees:x", 0, 0.5)			# reset pandangan 3
	tween_pandangan_3b.tween_property(self, "rotation_degrees:y", 0, 0.5)								# reset pandangan 3
	tween_pandangan_1.play()
	tween_pandangan_3a.play()
	tween_pandangan_3b.play()
	match nilai:
		1:	$animasi.play("pandangan_utama")
		3:	$animasi.play("pandangan_belakang") # TODO : Clipped Camera
func ubah_mode():
	match mode_kontrol:
		1: atur_mode(3)
		3: atur_mode(1)

func fungsikan(nilai):
	if nilai: 	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else: 		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	kontrol = nilai
