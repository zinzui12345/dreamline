extends CharacterBody3D

class_name Karakter

# TODO : floor_constant_speed = true, kecuali ketika menaiki tangga

var arah : Vector3
var arah_pandangan : Vector2 	# ini arah input / event relative
var arah_p_pandangan : Vector2 	# ini arah pose
var _menabrak = false
var _debug = false

@export var kontrol = false
@export var nama := ""+OS.get_model_name() :
	set(namaa):
		if get_node_or_null("nama") != null:
			$nama.text = namaa
		nama = namaa
@export var peran = Permainan.PERAN_KARAKTER.Arsitek
@export var platform_pemain := "Linux"
@export var id_pemain := -44 :
	set(id):
		$PlayerInput.call_deferred("atur_pengendali", id)
		id_pemain = id
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
	"mata"		: { "jalur_node": "wajah", "id_material": [5, 2] },
	"alis"		: { "jalur_node": "", "id_material": [4] },
	"rambut"	: { "jalur_node": "rambut", "id_material": [1, 2, 3] },
	"baju"		: { "jalur_node": "baju", "id_material": [0] },
	"celana"	: { "jalur_node": "celana", "id_material": [0] },
	"sepatu"	: { "jalur_node": "sepatu", "id_material": [0] }
}
@export var warna = {
	"mata" 		: Color.DARK_RED,
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

func _input(_event):
	if Input.is_action_just_pressed("debug"):
		if not _debug:
			print_debug("thefak")
			get_node("%GeneralSkeleton").physical_bones_start_simulation([
				"HairJoint-42e3c90b-142e-4348-83a2-8ad7f22661e9",
				"HairJoint-e9327431-fe35-4a5b-902c-528ff7c3e014_end",
				"HairJoint-4db0cf52-4216-43e0-8c2c-77b29cb83ca5_end",
				"HairJoint-e546e4f6-f6a6-42f5-838b-d09071115117_end"
			])
			_debug = true
		else:
			get_node("%GeneralSkeleton").physical_bones_stop_simulation()
			_debug = false

# penampilan
func atur_model():
	# alis | FaceBrow
	if model["alis"] != 0:
		var tmp_mtl = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["alis"])+"/alis.material")
		get_node("%GeneralSkeleton/wajah").set_surface_override_material(material["alis"]["id_material"][0], tmp_mtl)
	else:
		var tmp_mtl = load("res://karakter/"+$model.get_child(0).name+"/material/alis.material")
		get_node("%GeneralSkeleton/wajah").set_surface_override_material(material["alis"]["id_material"][0], tmp_mtl)
	
	# mata | EyeIris
	if model["mata"] != 0:
		var tmp_mtl = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["mata"])+"/mata.material")
		get_node("%GeneralSkeleton/"+material["mata"]["jalur_node"]).set_surface_override_material(material["mata"]["id_material"][0], tmp_mtl)
	else:
		var tmp_mtl = load("res://karakter/"+$model.get_child(0).name+"/material/mata.material")
		get_node("%GeneralSkeleton/"+material["mata"]["jalur_node"]).set_surface_override_material(material["mata"]["id_material"][0], tmp_mtl)
	
	# garis_mata | FaceEyeline | bulu_mata_a
	if model["garis_mata"] != 0:
		var tmp_mtl = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["garis_mata"])+"/bulu_mata_a.material")
		get_node("%GeneralSkeleton/"+material["mata"]["jalur_node"]).set_surface_override_material(material["mata"]["id_material"][1], tmp_mtl)
	else:
		var tmp_mtl = load("res://karakter/"+$model.get_child(0).name+"/material/bulu_mata_a.material")
		get_node("%GeneralSkeleton/"+material["mata"]["jalur_node"]).set_surface_override_material(material["mata"]["id_material"][1], tmp_mtl)
	
	if model["rambut"] != 0:
		var tmp_skin = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["rambut"])+"/rambut.scn").instantiate()
		var tmp_s_skin = get_node("%GeneralSkeleton/"+material["rambut"]["jalur_node"])
		tmp_skin.name = "rambut"
		tmp_s_skin.set_name("b_rambut")
		get_node("%GeneralSkeleton").add_child(tmp_skin.duplicate(8))
		tmp_skin.queue_free()
		#tmp_skin = get_node("%GeneralSkeleton/"+material["rambut"]["jalur_node"])
		tmp_s_skin.queue_free()
	else:
		var tmp_skin = load("res://karakter/"+$model.get_child(0).name+"/rambut.scn").instantiate()
		var tmp_s_skin = get_node("%GeneralSkeleton/"+material["rambut"]["jalur_node"])
		tmp_s_skin.set_name("b_rambut")
		get_node("%GeneralSkeleton").add_child(tmp_skin.duplicate(8))
		tmp_skin.queue_free()
		#tmp_skin = get_node("%GeneralSkeleton/"+material["rambut"]["jalur_node"])
		tmp_skin.skeleton = NodePath(get_node("%GeneralSkeleton").get_path())
		tmp_s_skin.queue_free()
	
	if model["baju"] != 0:
		var tmp_skin = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["baju"])+"/baju.scn").instantiate()
		var tmp_s_skin = get_node("%GeneralSkeleton").get_node(material["baju"]["jalur_node"])
		tmp_skin.name = "baju"
		tmp_s_skin.name = "b_baju"
		#tmp_skin.layers = tmp_s_skin.layers
		get_node("%GeneralSkeleton").add_child(tmp_skin.duplicate())
		tmp_skin.queue_free()
		tmp_s_skin.queue_free()
	else:
		var tmp_skin = load("res://karakter/"+$model.get_child(0).name+"/baju.scn").instantiate()
		var tmp_s_skin = get_node("%GeneralSkeleton").get_node(material["baju"]["jalur_node"])
		tmp_s_skin.name = "b_baju"
		#tmp_skin.layers = tmp_s_skin.layers
		get_node("%GeneralSkeleton").add_child(tmp_skin.duplicate())
		tmp_skin.queue_free()
		tmp_skin.skeleton = NodePath(get_node("%GeneralSkeleton").get_path())
		tmp_s_skin.queue_free()
	
	if model["sepatu"] != 0:
		var tmp_skin = load("res://karakter/"+$model.get_child(0).name+"/preset"+str(model["sepatu"])+"/sepatu.scn").instantiate()
		var tmp_s_skin = get_node("%GeneralSkeleton").get_node(material["sepatu"]["jalur_node"])
		tmp_skin.name = "sepatu"
		tmp_s_skin.name = "b_sepatu"
		#tmp_skin.layers = tmp_s_skin.layers
		get_node("%GeneralSkeleton").add_child(tmp_skin.duplicate())
		tmp_skin.queue_free()
		tmp_s_skin.queue_free()
	else:
		var tmp_skin = load("res://karakter/"+$model.get_child(0).name+"/sepatu.scn").instantiate()
		var tmp_s_skin = get_node("%GeneralSkeleton").get_node(material["sepatu"]["jalur_node"])
		tmp_s_skin.name = "b_sepatu"
		tmp_skin.layers = tmp_s_skin.layers
		get_node("%GeneralSkeleton").add_child(tmp_skin.duplicate())
		tmp_skin.queue_free()
		tmp_s_skin.queue_free()
	
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
						#print_debug("lavender mist")
						var src_mtl = get_node("%GeneralSkeleton/"+jlr_mtl).mesh.surface_get_material(id_mtl[mtl])
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
						get_node("%GeneralSkeleton/"+jlr_mtl).set_surface_override_material(id_mtl[mtl], tmp_mtl)
						if get_node_or_null("%GeneralSkeleton/"+jlr_mtl+"/"+jlr_mtl+"_f") != null\
						 and id_mtl[mtl] < get_node_or_null("%GeneralSkeleton/"+jlr_mtl+"/"+jlr_mtl+"_f").mesh.get_surface_count():
							get_node("%GeneralSkeleton/"+jlr_mtl+"/"+jlr_mtl+"_f").set_surface_override_material(id_mtl[mtl], tmp_mtl)
					tmp_mtl.set("shader_parameter/_Color", warna[indeks_material[mt]])
func atur_ragdoll(nilai):
	if nilai:	$model/Root/Skeleton3D.physical_bones_start_simulation()
	else:		$model/Root/Skeleton3D.physical_bones_stop_simulation()

# setup
func _ready():
	$pose.active = true
func _kendalikan(nilai):
	$pengamat.aktifkan(nilai) # ini harus di set true | false untuk layer visibilitas
	if kontrol != nilai: # gak usah  di terapin kalo nilai gak berubah
		$pengamat.fungsikan(nilai)
		kontrol = nilai
func _atur_kendali(nilai): 
	$pengamat.fungsikan(nilai)
	kontrol = nilai
func _hapus():
	set_physics_process(false)
	set_process(false)
	queue_free()

func _physics_process(_delta):
	# terapkan arah gerak
	if !is_on_floor() and arah.y > -(ProjectSettings.get_setting("physics/3d/default_gravity")): arah.y -= 0.1
	velocity = arah.rotated(Vector3.UP, global_transform.basis.get_euler().y)
	_menabrak = move_and_slide()
	
	# terapkan gerakan
	$pose.set("parameters/arah_gerakan/blend_position", Vector2(-arah_gerakan.x, arah_gerakan.z / 2))
	$pose.set("parameters/arah_jongkok/blend_position", arah_gerakan.z)
func _process(_delta):
	# kalkulasi gerakan
	arah.x = $PlayerInput.arah_gerakan.x
	arah.z = $PlayerInput.arah_gerakan.y
	
	# kalkulasi arah gerakan
	arah_gerakan = get_real_velocity() * transform.basis
	
	# atur posisi pengamat
	#$pengamat/kamera.position.x = get_node("%kepala").position.x # FIXME : attach ke leher ? gak usah
	$pengamat.position.y = get_node("%mata_kiri").position.y
	$pengamat/kamera.position.z = get_node("%kepala").position.z
	
	# atur arah pose
	$pose.set("parameters/arah_y_pandangan/blend_position", arah_p_pandangan.y)
