extends CharacterBody3D

class_name Karakter

# TODO : floor_constant_speed = true, kecuali ketika menaiki tangga

var arah : Vector3
var arah_gerakan : Vector3 :		# ini arah gerakan
	set(nilai):
		$pose.set("parameters/arah_gerakan/blend_position", Vector2(-nilai.x, nilai.z / 2)) # TODO : clamp arah gerak z > 0.25
		$pose.set("parameters/arah_jongkok/blend_position", nilai.z)
		arah_gerakan = nilai
var _transisi_reset_arah : Tween	# transisi ketika berhenti bergerak
var _input_arah_pandangan : Vector2	# ini arah input / event relative
var arah_pandangan : Vector2 :		# ini arah pose
	set(nilai):
		$pose.set("parameters/arah_x_pandangan/blend_position", nilai.x)
		$pose.set("parameters/arah_y_pandangan/blend_position", nilai.y)
		arah_pandangan = nilai
var gestur = "berdiri":				# ini mode gestur
	set(ubah):
		if ubah != $pose.get("parameters/gestur/current_state"):
			$pose.set("parameters/gestur/transition_request", ubah)
			match ubah:
				"berdiri":
					$pose.set("parameters/arah_pandangan_vertikal/blend_amount", 1)
					$pose.set("parameters/arah_pandangan_horizontal/blend_amount", 0)
				"duduk":
					$pose.set("parameters/arah_pandangan_vertikal/blend_amount", 0)
					$pose.set("parameters/arah_pandangan_horizontal/blend_amount", 1)
			gestur = ubah
var gestur_jongkok = 0.0 :
	set(nilai):
		# atur parameter pose
		$pose.set("parameters/jongkok/blend_amount", nilai)
		# 10/07/24 :: atur tinggi collider | setiap pemain menggunakan collider yang sama, buat tiap pemain memiliki collider unik
		if fisik_pemain == null:
			fisik_pemain = $fisik.shape.duplicate()
			$fisik.shape = fisik_pemain
		if fisik_area_tabrak_pemain == null:
			fisik_area_tabrak_pemain = $fisik.shape.duplicate()
			$area_tabrak/area.shape = fisik_area_tabrak_pemain
		var tinggi_jongkok = tinggi * 0.65625
		$fisik.shape.height = tinggi - ((tinggi - tinggi_jongkok) * nilai)
		$area_tabrak/area.shape.height = $fisik.shape.height + 0.02
		# terapkan nilai ke properti
		gestur_jongkok = nilai
var _menabrak = false
var _ragdoll = false :
	set(nilai):
		$pengamat.position.x 		= 0
		$pengamat.position.y 		= 0
		$pengamat.position.z 		= 0
		$pengamat/kamera.position.x = 0
		$pengamat/kamera.position.z = 0
		_ragdoll = nilai
var _timer_ragdoll : Timer
var penarget : RayCast3D
var penarget_serangan_a : RayCast3D
var menarget = false				# kondisi apakah sedang menarget objek
var objek_target : Node3D			# node/objek yang di target
var posisi_target : Vector3			# posisi titik temu target
var mode_menyerang = "a"			# ini mode serangan misalnya: a / b
var melompat = false : 
	set(lompat):
		if get_node_or_null("pose") != null:
			if lompat:
				$pose.set("parameters/melompat/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			melompat = lompat
var menyerang = false : 
	set(serang):
		if get_node_or_null("pose") != null:
			if serang:
				match gestur:
					"berdiri":
						match mode_menyerang:
							"a": $pose.set("parameters/mode_menyerang_berdiri/current_state", "mendorong")
						$pose.set("parameters/menyerang_berdiri/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
			menyerang = serang
var jongkok = false
var _interval_timeline	= 0.05
var _delay_timeline 	= _interval_timeline
var _frame_timeline_sb	= 0		# frame sebelumnya
var cek_perubahan_kondisi = {}	# simpan beberapa properti di tiap frame untuk membandingkan perubahan

@export var kontrol = false
@export var nama := ""+OS.get_model_name() :
	set(namaa):
		if get_node_or_null("nama") != null:
			$nama.text = namaa
		if namaa != "":
			nama = namaa
@export var gender := "P"
@export var peran = Permainan.PERAN_KARAKTER.Arsitek
@export var id_pemain := -44
@export var pose_duduk = "normal":
	set(ubah):
		if ubah != $pose.get("parameters/pose_duduk/current_state"):
			$pose.set("parameters/pose_duduk/transition_request", ubah)
			pose_duduk = ubah
@export var tinggi := 1.6		# tinggi pemain, ini disesuaikan untuk collider
@export var fisik_pemain : Shape3D = null				# collider pemain (unik di tiap instance)
@export var fisik_area_tabrak_pemain : Shape3D = null	# collider area serang pemain (unik di tiap instance)

@export var model = {
	"alis"		: 0,
	"bulu_mata"	: 0,
	"garis_mata": 0,
	"mata" 		: 0,
	"rambut"	: 0,
	"baju"		: 0,
	"celana"	: 0,
	"sepatu"	: 0
}
@export var ubah_model = {
	"rambut"	: false,
	"baju"		: false,
	"celana"	: false,
	"sepatu"	: false
}
@export var material = {
	"badan"		: { "jalur_node": "badan",	"id_material": [0] },
	"wajah"		: { "jalur_node": "wajah",	"id_material": [0, 1, 6, 7] },
	"mata"		: { "jalur_node": "wajah",	"id_material": [5, 2] },
	"telinga"	: { "jalur_node": "telinga","id_material": [0] },
	"alis"		: { "jalur_node": "",		"id_material": [4] },
	"rambut_"	: { "jalur_node": "badan",	"id_material": [1] },
	"rambut"	: { "jalur_node": "rambut",	"id_material": [0, 1, 2] },
	"baju"		: { "jalur_node": "baju",	"id_material": [0] },
	"celana"	: { "jalur_node": "celana",	"id_material": [0] },
	"sepatu"	: { "jalur_node": "sepatu",	"id_material": [0] }
}
@export var warna = {
	"badan"		: Color.WHITE,
	"wajah"		: Color.WHITE,
	"mata" 		: Color.DARK_RED,
	"telinga"	: Color.WHITE,
	"rambut_"	: Color.BLUE_VIOLET,
	"rambut"	: Color.BLUE_VIOLET,
	"baju"		: Color.AQUAMARINE,
	"celana"	: Color.WHITE,
	"sepatu"	: Color.WHITE
} :
	set(warna_baru):
		warna["mata"]	= warna_baru["mata"]
		warna["rambut"] = warna_baru["rambut"]
		warna["baju"]	= warna_baru["baju"]
		warna["celana"] = warna_baru["celana"]
		warna["sepatu"] = warna_baru["sepatu"]
		atur_warna()

@onready var posisi_awal = global_transform.origin
@onready var rotasi_awal = rotation

# penampilan
func atur_model():
	# alis | FaceBrow
	var tmp_alis
	if Konfigurasi.shader_karakter:
		tmp_alis = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["alis"])+"/material/shader/alis.material")
	else:
		tmp_alis = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["alis"])+"/material/normal/alis.material")
	get_node("%GeneralSkeleton/wajah").set_surface_override_material(material["alis"]["id_material"][0], tmp_alis)
	
	# mata | EyeIris
	var tmp_mata
	if Konfigurasi.shader_karakter:
		tmp_mata = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["mata"])+"/material/shader/mata.material")
	else:
		tmp_mata = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["mata"])+"/material/normal/mata.material")
	get_node("%GeneralSkeleton/"+material["mata"]["jalur_node"]).set_surface_override_material(material["mata"]["id_material"][0], tmp_mata)
	
	# garis_mata | FaceEyeline | bulu_mata_a
	var tmp_bulu_mata_a
	if Konfigurasi.shader_karakter:
		tmp_bulu_mata_a = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["garis_mata"])+"/material/shader/bulu_mata_a.material")
	else:
		tmp_bulu_mata_a = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["garis_mata"])+"/material/normal/bulu_mata_a.material")
	get_node("%GeneralSkeleton/"+material["mata"]["jalur_node"]).set_surface_override_material(material["mata"]["id_material"][1], tmp_bulu_mata_a)
	
	# rambut
	var src_mdl_rambut = get_node("%GeneralSkeleton/"+material["rambut"]["jalur_node"])
	var tmp_mdl_rambut = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["rambut"])+"/rambut.scn").instantiate()
	src_mdl_rambut.set_name("b_rambut")
	tmp_mdl_rambut.set_name("rambut")
	get_node("%GeneralSkeleton").add_child(tmp_mdl_rambut)
	src_mdl_rambut.queue_free()
	
	# baju
	var tmp_mdl_baju = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["baju"])+"/baju.scn").instantiate()
	var src_mdl_baju = get_node("%GeneralSkeleton").get_node(material["baju"]["jalur_node"])
	tmp_mdl_baju.name = "baju"
	src_mdl_baju.name = "b_baju"
	get_node("%GeneralSkeleton").add_child(tmp_mdl_baju.duplicate())
	tmp_mdl_baju.queue_free()
	src_mdl_baju.queue_free()
	
	# celana
	var tmp_mdl_celana = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["celana"])+"/celana.scn").instantiate()
	var src_mdl_celana = get_node("%GeneralSkeleton").get_node(material["celana"]["jalur_node"])
	tmp_mdl_celana.name = "celana"
	src_mdl_celana.name = "b_celana"
	get_node("%GeneralSkeleton").add_child(tmp_mdl_celana.duplicate())
	tmp_mdl_celana.queue_free()
	src_mdl_celana.queue_free()
	
	# sepatu
	var tmp_mdl_sepatu = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["sepatu"])+"/sepatu.scn").instantiate()
	var src_mdl_sepatu = get_node("%GeneralSkeleton").get_node(material["sepatu"]["jalur_node"])
	tmp_mdl_sepatu.name = "sepatu"
	src_mdl_sepatu.name = "b_sepatu"
	get_node("%GeneralSkeleton").add_child(tmp_mdl_sepatu.duplicate())
	tmp_mdl_sepatu.queue_free()
	src_mdl_sepatu.queue_free()
	
	atur_warna() # set ulang warna
func atur_warna():
	var indeks_material = material.keys()
	for mt in material.size():
		if material[indeks_material[mt]]["jalur_node"] != "":
			var jlr_mtl = material[indeks_material[mt]]["jalur_node"]
			var id_mtl	= material[indeks_material[mt]]["id_material"]
			for mtl in id_mtl.size():
				if get_node_or_null("%GeneralSkeleton/"+jlr_mtl) != null\
				 and warna.get(indeks_material[mt]) != null\
				 and id_mtl[mtl] < get_node("%GeneralSkeleton/"+jlr_mtl).mesh.get_surface_count():
					var tmp_mtl = get_node("%GeneralSkeleton/"+jlr_mtl).get_surface_override_material(id_mtl[mtl])
					if tmp_mtl == null:
						var src_mtl = get_node("%GeneralSkeleton/"+jlr_mtl).mesh.surface_get_material(id_mtl[mtl])
						if Konfigurasi.shader_karakter or src_mtl is ShaderMaterial:
							tmp_mtl = ShaderMaterial.new()
							tmp_mtl.shader = src_mtl.shader
							tmp_mtl.set_shader_parameter("_AlphaCutoutEnable", src_mtl.get_shader_parameter("_AlphaCutoutEnable"))
							tmp_mtl.set_shader_parameter("_Cutoff", src_mtl.get_shader_parameter("_Cutoff"))
							tmp_mtl.set_shader_parameter("_ShadeColor", src_mtl.get_shader_parameter("_ShadeColor"))
							tmp_mtl.set_shader_parameter("_MainTex_ST", src_mtl.get_shader_parameter("_MainTex_ST"))
							tmp_mtl.set_shader_parameter("_BumpScale", src_mtl.get_shader_parameter("_BumpScale"))
							tmp_mtl.set_shader_parameter("_ShadingGradeRate", src_mtl.get_shader_parameter("_ShadingGradeRate"))
							tmp_mtl.set_shader_parameter("_ShadingGradeRate", src_mtl.get_shader_parameter("_ShadingGradeRate"))
							tmp_mtl.set_shader_parameter("_ShadeShift", src_mtl.get_shader_parameter("_ShadeShift"))
							tmp_mtl.set_shader_parameter("_ShadeToony", src_mtl.get_shader_parameter("_ShadeToony"))
							tmp_mtl.set_shader_parameter("_LightColorAttenuation", src_mtl.get_shader_parameter("_LightColorAttenuation"))
							tmp_mtl.set_shader_parameter("_IndirectLightIntensity", src_mtl.get_shader_parameter("_IndirectLightIntensity"))
							tmp_mtl.set_shader_parameter("_RimColor", src_mtl.get_shader_parameter("_RimColor"))
							tmp_mtl.set_shader_parameter("_RimLightingMix", src_mtl.get_shader_parameter("_RimLightingMix"))
							tmp_mtl.set_shader_parameter("_RimFresnelPower", src_mtl.get_shader_parameter("_RimFresnelPower"))
							tmp_mtl.set_shader_parameter("_RimLift", src_mtl.get_shader_parameter("_RimLift"))
							tmp_mtl.set_shader_parameter("_MatcapColor", src_mtl.get_shader_parameter("_MatcapColor"))
							tmp_mtl.set_shader_parameter("_EmissionColor", src_mtl.get_shader_parameter("_EmissionColor"))
							tmp_mtl.set_shader_parameter("_EmissionMultiplier", src_mtl.get_shader_parameter("_EmissionMultiplier"))
							tmp_mtl.set_shader_parameter("_OutlineWidthMode", src_mtl.get_shader_parameter("_OutlineWidthMode"))
							tmp_mtl.set_shader_parameter("_OutlineWidth", src_mtl.get_shader_parameter("_OutlineWidth"))
							tmp_mtl.set_shader_parameter("_OutlineScaledMaxDistance", src_mtl.get_shader_parameter("_OutlineScaledMaxDistance"))
							tmp_mtl.set_shader_parameter("_OutlineColorMode", src_mtl.get_shader_parameter("_OutlineColorMode"))
							tmp_mtl.set_shader_parameter("_OutlineColor", src_mtl.get_shader_parameter("_OutlineColor"))
							tmp_mtl.set_shader_parameter("_OutlineLightingMix", src_mtl.get_shader_parameter("_OutlineLightingMix"))
							tmp_mtl.set_shader_parameter("_MainTex", src_mtl.get_shader_parameter("_MainTex"))
							tmp_mtl.set_shader_parameter("_ShadeTexture", src_mtl.get_shader_parameter("_ShadeTexture"))
							tmp_mtl.set_shader_parameter("_BumpMap", src_mtl.get_shader_parameter("_BumpMap"))
							tmp_mtl.set_shader_parameter("_SphereAdd", src_mtl.get_shader_parameter("_SphereAdd"))
							tmp_mtl.set_shader_parameter("_EmissionMap", src_mtl.get_shader_parameter("_EmissionMap"))
						else:
							tmp_mtl = StandardMaterial3D.new()
							#print_debug("lavender mist")
							tmp_mtl.cull_mode		= src_mtl.cull_mode #BaseMaterial3D.CULL_BACK
							tmp_mtl.albedo_texture 	= src_mtl.albedo_texture
							tmp_mtl.albedo_color	= src_mtl.albedo_color
							tmp_mtl.metallic		= src_mtl.metallic
							tmp_mtl.transparency	= src_mtl.transparency
						get_node("%GeneralSkeleton/"+jlr_mtl).set_surface_override_material(id_mtl[mtl], tmp_mtl)
						if get_node_or_null("%GeneralSkeleton/"+jlr_mtl+"/"+jlr_mtl+"_f") != null\
						 and id_mtl[mtl] < get_node_or_null("%GeneralSkeleton/"+jlr_mtl+"/"+jlr_mtl+"_f").mesh.get_surface_count():
							get_node("%GeneralSkeleton/"+jlr_mtl+"/"+jlr_mtl+"_f").set_surface_override_material(id_mtl[mtl], tmp_mtl)
						if jlr_mtl == "badan" and id_mtl[mtl] < get_node_or_null("%GeneralSkeleton/tangan").mesh.get_surface_count():
							get_node("%GeneralSkeleton/tangan").set_surface_override_material(id_mtl[mtl], tmp_mtl)
					if Konfigurasi.shader_karakter or tmp_mtl is ShaderMaterial:
						if indeks_material[mt] == "rambut_":
							tmp_mtl.set("shader_parameter/_Color", warna["rambut"])
						else:
							tmp_mtl.set("shader_parameter/_Color", warna[indeks_material[mt]])
					else:
						if indeks_material[mt] == "rambut_":
							tmp_mtl.albedo_color = warna["rambut"]
						else:
							tmp_mtl.albedo_color = warna[indeks_material[mt]]
func atur_ragdoll(nilai, percepatan : Vector3 = Vector3.ZERO):
	if nilai and !_ragdoll:
		var tmp_ragdoll = load("res://karakter/ragdoll.scn").instantiate()
		for f in (tmp_ragdoll.get_child(0).get_child_count()):
			if tmp_ragdoll.get_child(0).get_child(f) is PhysicalBone3D:
				$"%GeneralSkeleton".add_child(tmp_ragdoll.get_child(0).get_child(f).duplicate())
		tmp_ragdoll.queue_free()
		_ragdoll = true
		$pose.active = false
		$fisik.disabled = true # Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
		if id_pemain == client.id_koneksi: $pengamat.atur_mode(3)
		#$area_tabrak/area.disabled = true # Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
		$"%GeneralSkeleton".physical_bones_start_simulation()
		$"%GeneralSkeleton/fisik kerangka".apply_central_impulse(percepatan)
		$"%GeneralSkeleton/fisik kerangka/fisik pinggang".apply_central_impulse(percepatan)
		$"%GeneralSkeleton/fisik kerangka/fisik paha kiri".apply_central_impulse(percepatan)
		$"%GeneralSkeleton/fisik kerangka/fisik paha kanan".apply_central_impulse(percepatan)
		$"%GeneralSkeleton/fisik kerangka/fisik pinggang/fisik perut".apply_central_impulse(percepatan)
		if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
			if _timer_ragdoll == null:
				_timer_ragdoll = Timer.new()
				_timer_ragdoll.name = "timer bangkit"
				add_child(_timer_ragdoll)
				_timer_ragdoll.wait_time = 3
				_timer_ragdoll.connect("timeout", _ketika_bangkit)
			_timer_ragdoll.start()
	elif !nilai and _ragdoll:
		if id_pemain == client.id_koneksi: $pengamat.atur_mode(1)
		$"%GeneralSkeleton".physical_bones_stop_simulation()
		$"%GeneralSkeleton".get_node("fisik kerangka").queue_free()
		$pose.active = true
		$fisik.disabled = false # Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
		#$area_tabrak/area.disabled = false # Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
		global_position = percepatan
		_ragdoll = false
func hapus():
	set_physics_process(false)
	set_process(false)
	kontrol = false
	var indeks_material = material.keys()
	for mt in material.size():
		if material[indeks_material[mt]]["jalur_node"] != "":
			var jlr_mtl = material[indeks_material[mt]]["jalur_node"]
			var id_mtl	= material[indeks_material[mt]]["id_material"]
			for mtl in id_mtl.size():
				if get_node_or_null("%GeneralSkeleton/"+jlr_mtl) != null\
				 and warna.get(indeks_material[mt]) != null\
				 and id_mtl[mtl] < get_node("%GeneralSkeleton/"+jlr_mtl).mesh.get_surface_count():
					var tmp_mtl = get_node("%GeneralSkeleton/"+jlr_mtl).get_surface_override_material(id_mtl[mtl])
					if tmp_mtl != null:
						get_node("%GeneralSkeleton/"+jlr_mtl).set_surface_override_material(id_mtl[mtl], null)
	queue_free()

# setup
func _enter_tree():
	set_physics_process(false)
func _ready():
	$pose.active = true
	penarget = get_node("pengamat/%target")
	penarget_serangan_a = $area_serang_a
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		$area_tabrak.monitoring = true
		$area_tabrak.connect("body_entered", _ketika_ditabrak)
	# INFO : atur layer visibilitas model
	if id_pemain > 0 and id_pemain == client.id_koneksi:
		get_node("%GeneralSkeleton/badan/badan_f").set_layer_mask_value(2, true)
		get_node("%GeneralSkeleton/tangan").set_layer_mask_value(2, false)
	else:
		get_node("%GeneralSkeleton/badan/badan_f").set_layer_mask_value(2, false)
		get_node("%GeneralSkeleton/tangan").set_layer_mask_value(2, true)
		
		get_node("%GeneralSkeleton/rambut").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/wajah").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/kelopak_mata").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/badan").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/baju").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/celana").set_layer_mask_value(1, true)
		get_node("%GeneralSkeleton/sepatu").set_layer_mask_value(1, true)
func _atur_kendali(nilai):
	if nilai == false: arah = Vector3.ZERO
	if kontrol != nilai:
		$pengamat.fungsikan(nilai)
		$area_serang_a.enabled = nilai
		kontrol = nilai
func _atur_penarget(nilai):
	penarget.enabled = nilai
	if nilai == false: menarget = false

func _input(event):
	# kendalikan interaksi dengan input
	if kontrol:
		# arah pandangan
		if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			_input_arah_pandangan = event.relative
		if Input.is_action_pressed("pandangan_atas"):
			_input_arah_pandangan.y = -Input.get_action_strength("pandangan_atas")
		elif Input.is_action_pressed("pandangan_bawah"):
			_input_arah_pandangan.y = Input.get_action_strength("pandangan_bawah")
		if Input.is_action_pressed("pandangan_kiri"):
			_input_arah_pandangan.x = -Input.get_action_strength("pandangan_kiri")
		elif Input.is_action_pressed("pandangan_kanan"):
			_input_arah_pandangan.x = Input.get_action_strength("pandangan_kanan")
		
		# ubah mode pandangan
		if Input.is_action_just_pressed("mode_pandangan"): $pengamat.ubah_mode()
		
		# mode interaksi
		if Input.is_action_just_pressed("debug"):	server.permainan.pilih_mode_bermain()
		if Input.is_action_just_pressed("debug2"):	server.permainan.pilih_mode_edit()
		
		# aksi
		if Input.is_action_just_pressed("aksi1") or Input.is_action_just_pressed("aksi1_sentuh"):
			if server.permainan.get_node("kontrol_sentuh").visible and !Input.is_action_pressed("aksi1_sentuh"): pass # cegah pada layar sentuh, tapi tetap bisa dengan klik virtual
			elif menarget:
				match peran:
					Permainan.PERAN_KARAKTER.Arsitek:
						server.permainan.pasang_objek = posisi_target
						server.permainan._tampilkan_daftar_objek()
					_:
						if objek_target.is_in_group("dapat_diedit") and objek_target.has_node("kode_ubahan"):
							if objek_target.id_pengubah < 1:
								objek_target.get_node("kode_ubahan").panggil_fungsi_kode("gunakan", multiplayer.get_unique_id())
						elif penarget_serangan_a.is_colliding() and gestur == "berdiri" and not menyerang:
							objek_target = penarget_serangan_a.get_collider()
							var arah_dorongan = Vector3(0, 0, 5)
							if objek_target.get("linear_velocity") != null:
								mode_menyerang = "a"
								set("menyerang", true)
								await get_tree().create_timer(0.4).timeout
								if objek_target != null:
									server.terapkan_percepatan_objek(
										objek_target.get_path(),
										arah_dorongan.rotated(Vector3.UP, rotation.y)
									)
								await get_tree().create_timer(0.4).timeout
								set("menyerang", false)
							elif objek_target is Karakter:
								var id_target = objek_target.id_pemain
								mode_menyerang = "a"
								set("menyerang", true)
								await get_tree().create_timer(0.2).timeout
								if objek_target != null:
									server.dorong_pemain(id_target, arah_dorongan.rotated(Vector3.UP, rotation.y))
								set("menyerang", false)
		if Input.is_action_just_pressed("aksi2"):
			if menarget:
				match peran:
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
				match peran:
					Permainan.PERAN_KARAKTER.Arsitek:
						if server.permainan.memasang_objek: server.permainan._tutup_daftar_objek()
func _physics_process(delta):
	# kendalikan karakter dengan input
	if kontrol:
		# maju / mundur
		if Input.is_action_pressed("berlari"):
			if is_on_floor():
				arah.z = Input.get_action_strength("berlari") * 2
				if Input.is_action_pressed("mundur"):
					arah.z = -Input.get_action_strength("berlari") * 2
			elif Input.is_action_pressed("kiri") or Input.is_action_pressed("kanan"):
				arah.z = lerp(arah.z, Input.get_action_strength("berlari") * 2, 0.5 * delta)
		elif Input.is_action_pressed("maju"):
			arah.z = Input.get_action_strength("maju")
		elif Input.is_action_pressed("mundur"):
			arah.z = -Input.get_action_strength("mundur")
		else:
			if is_on_floor():
				if self.is_inside_tree():
					if _transisi_reset_arah == null:
						_transisi_reset_arah = get_tree().create_tween()
						_transisi_reset_arah.stop()
						_transisi_reset_arah.tween_property(self, "arah", Vector3.FORWARD * 0.0, 0.35)
						_transisi_reset_arah.set_trans(Tween.TRANS_SPRING)
						_transisi_reset_arah.set_ease(Tween.EASE_OUT)
						_transisi_reset_arah.play()
					elif !_transisi_reset_arah.is_running():
						_transisi_reset_arah = null
			else: arah.z = lerp(arah.z, 0.0, 0.5 * delta)
		
		# kiri / kanan
		if Input.is_action_pressed("kiri"):
			if Input.is_action_pressed("berlari"): arah.x = Input.get_action_strength("kiri")
			else: arah.x = Input.get_action_strength("kiri") / 2
		elif Input.is_action_pressed("kanan"):
			if Input.is_action_pressed("berlari"): arah.x = -Input.get_action_strength("kanan")
			else: arah.x = -Input.get_action_strength("kanan") / 2
		else: arah.x = 0
		
		# lompat
		if Input.is_action_pressed("lompat"):
			if !melompat:
				if Input.is_action_pressed("berlari") and arah.z > 1.0:
					if is_on_floor():
						arah.y = 180 * delta
					elif (Input.is_action_pressed("kiri") and _input_arah_pandangan.x > 0) \
					 or (Input.is_action_pressed("kanan") and _input_arah_pandangan.x < 0):
						arah.y = clampf(arah.y * 1.4, 180 * delta, 250 * delta)
						if Input.is_action_pressed("mundur"):
							arah.z = -clampf(arah.z * 1.05, 0.0, 250 * delta)
						else:
							arah.z = clampf(arah.z * 1.025, 0.0, 250 * delta)
				elif is_on_floor():
					melompat = true
					arah.y = 150 * delta
		elif is_on_floor() and melompat:
			melompat = false
		
		# jongkok
		if Input.is_action_just_pressed("jongkok"):
			if arah.x == 0.0 and arah.z == 0.0:
				if !jongkok:
					#$pose.set("parameters/gestur/transition_request", "jongkok")
					var tween = get_tree().create_tween()
					tween.tween_property(self, "gestur_jongkok", 1, 0.6)
					jongkok = true
					tween.play()
				else:
					#$pose.set("parameters/gestur/transition_request", "berdiri")
					var tween = get_tree().create_tween()
					tween.tween_property(self, "gestur_jongkok", 0, 0.6)
					jongkok = false
					tween.play()
	
	# fungsi raycast
	menarget = penarget.is_colliding()
	if menarget and penarget.get_collider() != null:
		posisi_target = penarget.get_collision_point()
		objek_target = penarget.get_collider()
		if peran == Permainan.PERAN_KARAKTER.Arsitek:
			# atur posisi pointer
			if !server.permainan.dunia.get_node("kursor_objek").visible:
				server.permainan.dunia.get_node("kursor_objek").visible = true
			server.permainan.dunia.get_node("kursor_objek").global_transform.origin = posisi_target
			# tampilkan tombol buat objek
			server.permainan.set("tombol_aksi_1", "pasang_objek")
			server.permainan.get_node("kontrol_sentuh/aksi_1").visible = true
			server.permainan.get_node("hud/bantuan_input/aksi1").visible = true
		elif penarget_serangan_a.is_colliding() and gestur == "berdiri" and objek_target == penarget_serangan_a.get_collider():
			server.permainan.set("tombol_aksi_1", "dorong_sesuatu")
			server.permainan.get_node("kontrol_sentuh/aksi_1").visible = true
			server.permainan.get_node("hud/bantuan_input/aksi1").visible = true
		elif objek_target.is_in_group("dapat_diedit") and objek_target.has_node("kode_ubahan"):
			server.permainan.set("tombol_aksi_1", "gunakan_objek")
			server.permainan.get_node("kontrol_sentuh/aksi_1").visible = true
			server.permainan.get_node("hud/bantuan_input/aksi1").visible = true
		else:
			server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
			server.permainan.get_node("hud/bantuan_input/aksi1").visible = false
		if peran == Permainan.PERAN_KARAKTER.Arsitek and objek_target.is_in_group("dapat_diedit"):
			server.permainan.set("tombol_aksi_2", "edit_objek")
			server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
			server.permainan.get_node("hud/bantuan_input/aksi2").visible = true
		elif objek_target.has_method("gunakan") or (objek_target.name == "bidang_raycast" and objek_target.get_parent().has_method("gunakan")):
			if peran == Permainan.PERAN_KARAKTER.Arsitek:
				server.permainan.set("tombol_aksi_2", "edit_objek")
			else:
				if objek_target.has_method("fokus"): objek_target.fokus()
				if objek_target.get_parent().has_method("gunakan"): objek_target.get_parent().fokus()
			server.permainan.get_node("kontrol_sentuh/aksi_2").visible = true
			server.permainan.get_node("hud/bantuan_input/aksi2").visible = true
		elif objek_target is npc_ai and objek_target.get("posisi_bar_nyawa") != null:
			if !server.permainan.dunia.get_node("bar_nyawa").visible:
				server.permainan.dunia.get_node("bar_nyawa").visible = true
			server.permainan.dunia.get_node("bar_nyawa").global_position =  Vector3(
				objek_target.global_position.x,
				objek_target.global_position.y + objek_target.posisi_bar_nyawa,
				objek_target.global_position.z
			)
			server.permainan.dunia.get_node("bar_nyawa").max_value = 150
			server.permainan.dunia.get_node("bar_nyawa").value = objek_target.nyawa
		else:
			server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
			server.permainan.get_node("hud/bantuan_input/aksi2").visible = false
	elif is_instance_valid(objek_target):
		objek_target = null
		if server.permainan.get_node("kontrol_sentuh/aksi_1").visible:
			server.permainan.get_node("kontrol_sentuh/aksi_1").visible = false
			server.permainan.get_node("hud/bantuan_input/aksi1").visible = false
		if server.permainan.get_node("kontrol_sentuh/aksi_2").visible:
			server.permainan.get_node("kontrol_sentuh/aksi_2").visible = false
			server.permainan.get_node("hud/bantuan_input/aksi2").visible = false
		if server.permainan.dunia.get_node("kursor_objek").visible:
			server.permainan.dunia.get_node("kursor_objek").visible = false
		if server.permainan.dunia.get_node("bar_nyawa").visible:
			server.permainan.dunia.get_node("bar_nyawa").visible = false
	
	# atur ulang posisi kalau terjatuh dari dunia
	if global_position.y < server.permainan.batas_bawah:
		global_transform.origin = posisi_awal
		rotation		 		= rotasi_awal
		Panku.notify("re-spawn")
	
	# kalkulasi arah gerakan
	arah_gerakan = get_real_velocity() * transform.basis
	
	# sinkronkan perubahan kondisi
	if id_pemain == client.id_koneksi:
		# buat variabel pembanding
		var perubahan_kondisi = []
		
		# cek apakah kondisi sebelumnya telah tersimpan, jika belum set ke nilai kosong
		if cek_perubahan_kondisi.get("posisi") == null:
			cek_perubahan_kondisi["posisi"] = Vector3.ZERO
		if cek_perubahan_kondisi.get("rotasi") == null:
			cek_perubahan_kondisi["rotasi"] = Vector3.ZERO
		if cek_perubahan_kondisi.get("arah_pandangan") == null:
			cek_perubahan_kondisi["arah_pandangan"] = Vector2.ZERO
		if cek_perubahan_kondisi.get("arah_gerakan") == null:
			cek_perubahan_kondisi["arah_gerakan"] = Vector3.ZERO
		if cek_perubahan_kondisi.get("mode_gestur") == null:
			cek_perubahan_kondisi["mode_gestur"] = "berdiri"
		if cek_perubahan_kondisi.get("gestur_jongkok") == null:
			cek_perubahan_kondisi["gestur_jongkok"] = 0.0
		if cek_perubahan_kondisi.get("mode_menyerang") == null:
			cek_perubahan_kondisi["mode_menyerang"] = "a"
		if cek_perubahan_kondisi.get("melompat") == null:
			cek_perubahan_kondisi["melompat"] = false
		if cek_perubahan_kondisi.get("menyerang") == null:
			cek_perubahan_kondisi["menyerang"] = false
		
		# cek apakah kondisi berubah
		if cek_perubahan_kondisi["posisi"] != position:
			perubahan_kondisi.append(["posisi", position])
		if cek_perubahan_kondisi["rotasi"] != rotation:
			perubahan_kondisi.append(["rotasi", rotation])
		if cek_perubahan_kondisi["arah_pandangan"] != arah_pandangan:
			perubahan_kondisi.append(["arah_pandangan", arah_pandangan])
		if cek_perubahan_kondisi["arah_gerakan"] != arah_gerakan:
			perubahan_kondisi.append(["arah_gerakan", arah_gerakan])
		if cek_perubahan_kondisi["mode_gestur"] != gestur:
			perubahan_kondisi.append(["mode_gestur", gestur])
		if cek_perubahan_kondisi["gestur_jongkok"] != gestur_jongkok:
			perubahan_kondisi.append(["gestur_jongkok", gestur_jongkok])
		if cek_perubahan_kondisi["mode_menyerang"] != mode_menyerang:
			perubahan_kondisi.append(["mode_menyerang", mode_menyerang])
		if cek_perubahan_kondisi["melompat"] != melompat:
			perubahan_kondisi.append(["melompat", melompat])
		if cek_perubahan_kondisi["menyerang"] != menyerang:
			perubahan_kondisi.append(["menyerang", menyerang])
		
		# jika kondisi berubah, maka sinkronkan perubahan ke server
		if perubahan_kondisi.size() > 0:
			if id_pemain == 1 and client.id_koneksi == 1:
				server._sesuaikan_kondisi_pemain("admin", 1, perubahan_kondisi)
			else:
				server.rpc_id(1, "_sesuaikan_kondisi_pemain", client.id_sesi, client.id_koneksi, perubahan_kondisi)
		
		# simpan perubahan kondisi untuk di-cek lagi
		cek_perubahan_kondisi["posisi"] = position
		cek_perubahan_kondisi["rotasi"] = rotation
		cek_perubahan_kondisi["melompat"] = melompat
		cek_perubahan_kondisi["menyerang"] = menyerang
		cek_perubahan_kondisi["mode_gestur"] = gestur
		cek_perubahan_kondisi["arah_gerakan"] = arah_gerakan
		cek_perubahan_kondisi["arah_pandangan"] = arah_pandangan
		cek_perubahan_kondisi["gestur_jongkok"] = gestur_jongkok
		cek_perubahan_kondisi["mode_menyerang"] = mode_menyerang
	
	# terapkan arah gerakan
	if !is_on_floor() and arah.y > -(ProjectSettings.get_setting("physics/3d/default_gravity")): arah.y -= 0.1
	elif is_on_floor() and arah.y < 0: arah.y = 0
	# jangan fungsikan kendali kalo animasi gak aktif
	if $pose.active: velocity = arah.rotated(Vector3.UP, global_transform.basis.get_euler().y)
	_menabrak = move_and_slide()
func _process(delta):
	# atur posisi pengamat
	if _ragdoll:
		$pengamat.global_position.x = get_node("%pinggang").global_position.x
		$pengamat.global_position.y = get_node("%pinggang").global_position.y
		$pengamat.global_position.z = get_node("%pinggang").global_position.z
	else:
		$pengamat/kamera.position.x = 0
		$pengamat.position.y 		= get_node("%mata_kiri").position.y
		$pengamat/kamera.position.z = get_node("%mata_kiri").position.z

func _ketika_ditabrak(node):
	var percepatan = node.get_linear_velocity()
	var hantaman = 0
	
	# Terapkan arah Area
	$area_tabrak.look_at(node.global_position, Vector3.UP, true)
	$area_tabrak.rotation_degrees.x = 0
	$area_tabrak.rotation_degrees.z = 0
	
	# Dapatkan transformasi dari Area3D
	var area_transform = $area_tabrak.global_transform
	
	# Gunakan matriks rotasi dari transformasi area
	var area_rotation = area_transform.basis
	
	# Arah dari area adalah vektor ke depan (0, 0, 1) yang diubah dengan matriks rotasi area
	var area_direction = Vector3(0, 0, 1) * area_rotation
	
	var direction = percepatan.normalized()
	var alignment = area_direction.dot(direction)
	
	# Jika arah kecepatan linear mengarah tepat ke area
	if alignment > 0.99:  # Misalnya, jika arah mendekati 1, hampir tepat ke area
		hantaman = percepatan.length()  # Total dari kecepatan linear
	else:
		# Jika arah kecepatan linear tidak tepat ke area
		hantaman = percepatan.length() * alignment  # Persentase ketepatan arah node ke area
	hantaman = abs(hantaman)
	
	if node.get("radius_tabrak") != null:
		hantaman = hantaman * node.radius_tabrak
		if hantaman >= 10:
			atur_ragdoll(true, percepatan / 2)
			server.fungsikan_objek(get_path(), "atur_ragdoll", [true, percepatan/2])
	
	# TODO : nyawa!?
	 
	#Panku.notify(node.name+" menabrak "+name+" : "+str(hantaman))
func _ketika_bangkit(): # bangkit kembali setelah menjadi ragdoll
	if is_instance_valid($"%GeneralSkeleton/fisik kerangka"):
		var total_percepatan_kerangka = $"%GeneralSkeleton/fisik kerangka".linear_velocity.abs()
		var percepatan_kerangka = total_percepatan_kerangka.x + total_percepatan_kerangka.y + total_percepatan_kerangka.z
		var posisi_bangkit = $"%GeneralSkeleton/fisik kerangka/fisik pusat".global_position
		if percepatan_kerangka < 0.1: # atur ulang setelah tidak ada gaya
			_timer_ragdoll.stop()
			atur_ragdoll(false, posisi_bangkit)
			server.fungsikan_objek(get_path(), "atur_ragdoll", [false, posisi_bangkit])
		elif $"%GeneralSkeleton/fisik kerangka".global_position.y < server.permainan.batas_bawah: # atur ulang posisi kalau terjatuh dari dunia
			_timer_ragdoll.stop()
			atur_ragdoll(false, global_position)
			server.fungsikan_objek(get_path(), "atur_ragdoll", [false, global_position])
