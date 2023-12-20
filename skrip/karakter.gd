extends CharacterBody3D

class_name Karakter

# TODO : floor_constant_speed = true, kecuali ketika menaiki tangga

var arah : Vector3
var arah_pandangan : Vector2 	# ini arah input / event relative
var arah_p_pandangan : Vector2 :# ini arah pose
	set(nilai):
		$pose.set("parameters/arah_x_pandangan/blend_position", nilai.x)
		$pose.set("parameters/arah_y_pandangan/blend_position", nilai.y)
		arah_p_pandangan = nilai
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
var tekstur

@export var kontrol = false
@export var nama := ""+OS.get_model_name() :
	set(namaa):
		if get_node_or_null("nama") != null:
			$nama.text = namaa
		if namaa != "":
			nama = namaa
@export var gender := "P"
@export var peran = Permainan.PERAN_KARAKTER.Arsitek
@export var id_sistem = ""
@export var platform_pemain := "Linux"
@export var id_pemain := -44 :
	set(id):
		$PlayerInput.call_deferred("atur_pengendali", id)
		id_pemain = id
@export var gestur = "berdiri":
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
@export var pose_duduk = "normal":
	set(ubah):
		if ubah != $pose.get("parameters/pose_duduk/current_state"):
			$pose.set("parameters/pose_duduk/transition_request", ubah)
			pose_duduk = ubah
@export var lompat = false : 
	set(melompat):
		if melompat:
			# track dan keyframe belum ada
			#$model/animasi.get_animation("animasi/melompat").track_set_key_value(57, 0, true)
			#$model/animasi.get_animation("animasi/melompat").track_set_key_value(57, 1, true)
			#$model/animasi.get_animation("animasi/melompat").track_set_key_value(57, 4, true)
			#$model/animasi.get_animation("animasi/melompat").track_set_key_value(57, 5, true)
			#$model/animasi.get_animation("animasi/melompat").track_set_key_value(58, 0, $PlayerInput.arah_gerakan)
			$pose.set("parameters/melompat/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		lompat = melompat
@export var arah_gerakan : Vector3
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
	"badan"		: { "jalur_node": "badan", "id_material": [0] },
	"wajah"		: { "jalur_node": "wajah", "id_material": [0, 1, 6, 7] },
	"mata"		: { "jalur_node": "wajah", "id_material": [5, 2] },
	"telinga"	: { "jalur_node": "telinga", "id_material": [0] },
	"tangan"	: { "jalur_node": "rambut", "id_material": [0] },
	"alis"		: { "jalur_node": "", "id_material": [4] },
	"rambut"	: { "jalur_node": "rambut", "id_material": [1, 2, 3] },
	"baju"		: { "jalur_node": "baju", "id_material": [0] },
	"celana"	: { "jalur_node": "celana", "id_material": [0] },
	"sepatu"	: { "jalur_node": "sepatu", "id_material": [0] }
}
@export var warna = {
	"badan"		: Color.WHITE,
	"wajah"		: Color.WHITE,
	"mata" 		: Color.DARK_RED,
	"telinga"	: Color.WHITE,
	"tangan"	: Color.WHITE,
	"rambut"	: Color.BLUE_VIOLET,
	"baju"		: Color.AQUAMARINE,
	"celana"	: Color.WHITE,
	"sepatu"	: Color.WHITE
} :
	set(warna_baru):
		warna["mata"] = warna_baru["mata"]
		warna["rambut"] = warna_baru["rambut"]
		warna["baju"] = warna_baru["baju"]
		warna["celana"] = warna_baru["celana"]
		warna["sepatu"] = warna_baru["sepatu"]
		atur_warna()

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
							#if get_parent().get_path() == server.permainan.dunia.get_node("pemain").get_path():
							#	get_node("%GeneralSkeleton/"+jlr_mtl+"/"+jlr_mtl+"_f").mesh.surface_set_material(id_mtl[mtl], null)
						#if get_parent().get_path() == server.permainan.dunia.get_node("pemain").get_path():
							#get_node("%GeneralSkeleton/"+jlr_mtl).mesh.surface_set_material(id_mtl[mtl], null)
					if Konfigurasi.shader_karakter or tmp_mtl is ShaderMaterial:
						tmp_mtl.set("shader_parameter/_Color", warna[indeks_material[mt]])
					else: tmp_mtl.albedo_color = warna[indeks_material[mt]]
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
		$pengamat.atur_mode(3)
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
		$pengamat.atur_mode(1)
		$"%GeneralSkeleton".physical_bones_stop_simulation()
		$"%GeneralSkeleton".get_node("fisik kerangka").queue_free()
		$pose.active = true
		$fisik.disabled = false # Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
		#$area_tabrak/area.disabled = false # Can't change this state while flushing queries. Use call_deferred() or set_deferred() to change monitoring state instead.
		global_position = percepatan
		_ragdoll = false

# setup
func _ready():
	$pose.active = true
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		$area_tabrak.monitoring = true
		$area_tabrak.connect("body_entered", _ketika_ditabrak)
func _kendalikan(nilai):
	$pengamat.aktifkan(nilai) # ini harus di set true | false untuk layer visibilitas
	if kontrol != nilai: # gak usah  di terapin kalo nilai gak berubah
		$pengamat.fungsikan(nilai)
		kontrol = nilai
func _atur_kendali(nilai): 
	$pengamat.fungsikan(nilai)
	$PlayerInput.arah_gerakan = Vector2.ZERO
	kontrol = nilai
func _hapus():
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

func _physics_process(_delta):
	if $pose.active: # jangan fungsikan kalo animasi gak aktif
		# terapkan arah gerak
		if !is_on_floor() and arah.y > -(ProjectSettings.get_setting("physics/3d/default_gravity")): arah.y -= 0.1
		elif is_on_floor() and arah.y < 0: arah.y = 0
		velocity = arah.rotated(Vector3.UP, global_transform.basis.get_euler().y)
		_menabrak = move_and_slide()
		
		# terapkan gerakan
		$pose.set("parameters/arah_gerakan/blend_position", Vector2(-arah_gerakan.x, arah_gerakan.z / 2)) # TODO : clamp arah gerak z > 0.25
		$pose.set("parameters/arah_jongkok/blend_position", arah_gerakan.z)
func _process(_delta):
	# kalkulasi gerakan
	arah.x = $PlayerInput.arah_gerakan.x
	arah.z = $PlayerInput.arah_gerakan.y
	
	# kalkulasi arah gerakan
	arah_gerakan = get_real_velocity() * transform.basis
	
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
