extends CharacterBody3D

class_name Karakter

# TODO : floor_constant_speed = true, kecuali ketika menaiki tangga

var arah : Vector3
var arah_pandangan : Vector2
var _menabrak = false
var _debug = false

@export var kontrol = false
@export var nama := ""+OS.get_model_name() :
	set(namaa):
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
	"alis"		: false,
	"bulu_mata"	: false,
	"garis_mata": false,
	"mata" 		: false,
	"rambut"	: false,
	"baju"		: false,
	"celana"	: false,
	"sepatu"	: false
}
@export var material = {
	"mata"		: { "jalur_node": "wajah", "id_material": [5] },
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
	"sepatu"	: Color.DARK_CYAN
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
			$model/Root/Skeleton3D.physical_bones_start_simulation([
				"HairJoint-42e3c90b-142e-4348-83a2-8ad7f22661e9",
				"HairJoint-e9327431-fe35-4a5b-902c-528ff7c3e014_end",
				"HairJoint-4db0cf52-4216-43e0-8c2c-77b29cb83ca5_end",
				"HairJoint-e546e4f6-f6a6-42f5-838b-d09071115117_end"
			])
			_debug = true
		else:
			$model/Root/Skeleton3D.physical_bones_stop_simulation()
			_debug = false

# penampilan
func atur_model():
	if model["alis"] != 0:
		var tmp_mtl
		if ubah_model["alis"] == false:
			tmp_mtl = $model/Root/Skeleton3D.get_node("wajah").get_surface_override_material(material["alis"]["id_material"][0]).duplicate(8)
			ubah_model["alis"] = true
		else:
			tmp_mtl = $model/Root/Skeleton3D.get_node("wajah").get_surface_override_material(material["alis"]["id_material"][0])
		tmp_mtl.albedo_texture = load("res://karakter/lulu/preset"+str(model["alis"])+"/alis.png")
		$model/Root/Skeleton3D.get_node("wajah").set_surface_override_material(material["alis"]["id_material"][0], tmp_mtl)
	else:
		var tmp_mtl = $model/Root/Skeleton3D.get_node("wajah").get_surface_override_material(material["alis"]["id_material"][0])
		tmp_mtl.albedo_texture = load("res://karakter/lulu/tekstur/alis.png")
		$model/Root/Skeleton3D.get_node("wajah").set_surface_override_material(material["alis"]["id_material"][0], tmp_mtl)
	
	if model["mata"] != 0:
		var tmp_mtl
		if ubah_model["mata"] == false:
			tmp_mtl = $model/Root/Skeleton3D.get_node(material["mata"]["jalur_node"]).get_surface_override_material(material["mata"]["id_material"][0]).duplicate(8)
			ubah_model["mata"] = true
		else:
			tmp_mtl = $model/Root/Skeleton3D.get_node(material["mata"]["jalur_node"]).get_surface_override_material(material["mata"]["id_material"][0])
		tmp_mtl.albedo_texture = load("res://karakter/lulu/preset"+str(model["mata"])+"/mata.png")
		$model/Root/Skeleton3D.get_node(material["mata"]["jalur_node"]).set_surface_override_material(material["mata"]["id_material"][0], tmp_mtl)
	else:
		var tmp_mtl = $model/Root/Skeleton3D.get_node(material["mata"]["jalur_node"]).get_surface_override_material(material["mata"]["id_material"][0])
		tmp_mtl.albedo_texture = load("res://karakter/lulu/tekstur/mata.png")
		$model/Root/Skeleton3D.get_node(material["mata"]["jalur_node"]).set_surface_override_material(material["mata"]["id_material"][0], tmp_mtl)
	
	if model["garis_mata"] != 0:
		var tmp_mtl
		if ubah_model["garis_mata"] == false:
			tmp_mtl = $model/Root/Skeleton3D.get_node(material["mata"]["jalur_node"]).get_surface_override_material(2).duplicate(8)
			ubah_model["garis_mata"] = true
		else:
			tmp_mtl = $model/Root/Skeleton3D.get_node(material["mata"]["jalur_node"]).get_surface_override_material(2)
		tmp_mtl.albedo_texture = load("res://karakter/lulu/preset"+str(model["garis_mata"])+"/bulu_mata_a.png")
		$model/Root/Skeleton3D.get_node(material["mata"]["jalur_node"]).set_surface_override_material(2, tmp_mtl)
	else:
		var tmp_mtl = $model/Root/Skeleton3D.get_node(material["mata"]["jalur_node"]).get_surface_override_material(2)
		tmp_mtl.albedo_texture = load("res://karakter/lulu/tekstur/bulu_mata_a.png")
		$model/Root/Skeleton3D.get_node(material["mata"]["jalur_node"]).set_surface_override_material(2, tmp_mtl)
	
	if model["rambut"] != 0:
		var tmp_skin = load("res://karakter/lulu/preset"+str(model["rambut"])+"/rambut.scn").instantiate()
		var tmp_s_skin = $model/Root/Skeleton3D.get_node(material["rambut"]["jalur_node"])
		tmp_skin.name = "rambut"
		tmp_s_skin.set_name("b_rambut")
		tmp_skin.layers = tmp_s_skin.layers
		$model/Root/Skeleton3D.add_child(tmp_skin.duplicate(8))
		tmp_skin.queue_free()
		tmp_skin = $model/Root/Skeleton3D.get_node(material["rambut"]["jalur_node"])
		for mtl in tmp_skin.mesh.get_surface_count():
			var tmp_mtl
			if ubah_model["rambut"] == false:
				tmp_mtl = tmp_s_skin.get_surface_override_material(mtl).duplicate(8)
				ubah_model["rambut"] = true
			else:
				tmp_mtl = tmp_s_skin.get_surface_override_material(mtl)
			tmp_skin.set_surface_override_material(mtl, tmp_mtl)
		tmp_s_skin.queue_free()
	else:
		var tmp_skin = load("res://karakter/lulu/rambut.scn").instantiate()
		var tmp_s_skin = $model/Root/Skeleton3D.get_node(material["rambut"]["jalur_node"])
		tmp_s_skin.set_name("b_rambut")
		tmp_skin.layers = tmp_s_skin.layers
		$model/Root/Skeleton3D.add_child(tmp_skin.duplicate(8))
		tmp_skin.queue_free()
		tmp_skin = $model/Root/Skeleton3D.get_node(material["rambut"]["jalur_node"])
		for mtl in tmp_skin.mesh.get_surface_count():
			var tmp_mtl = tmp_s_skin.get_surface_override_material(mtl).duplicate(8)
			tmp_skin.set_surface_override_material(mtl, tmp_mtl)
		tmp_skin.skeleton = NodePath($model/Root/Skeleton3D.get_path())
		tmp_s_skin.queue_free()
	
	if model["baju"] != 0:
		var tmp_skin = load("res://karakter/lulu/preset"+str(model["baju"])+"/baju.scn").instantiate()
		var tmp_s_skin = $model/Root/Skeleton3D.get_node(material["baju"]["jalur_node"])
		tmp_skin.name = "baju"
		tmp_s_skin.name = "b_baju"
		tmp_skin.layers = tmp_s_skin.layers
		$model/Root/Skeleton3D.add_child(tmp_skin.duplicate())
		tmp_skin.queue_free()
		tmp_skin = $model/Root/Skeleton3D.get_node(material["baju"]["jalur_node"])
		for mtl in tmp_skin.mesh.get_surface_count():
			var tmp_s_mtl = tmp_s_skin.get_surface_override_material(mtl)
			var tmp_mtl
			if ubah_model["baju"] == false:
				tmp_mtl = tmp_skin.mesh.surface_get_material(mtl).duplicate(8)
				ubah_model["baju"] = true
			else:
				tmp_mtl = tmp_skin.mesh.surface_get_material(mtl)
			tmp_mtl.albedo_color = tmp_s_mtl.albedo_color
			tmp_skin.set_surface_override_material(mtl, tmp_mtl)
		tmp_s_skin.queue_free()
	else:
		var tmp_skin = load("res://karakter/lulu/baju.scn").instantiate()
		var tmp_s_skin = $model/Root/Skeleton3D.get_node(material["baju"]["jalur_node"])
		tmp_s_skin.name = "b_baju"
		tmp_skin.layers = tmp_s_skin.layers
		$model/Root/Skeleton3D.add_child(tmp_skin.duplicate())
		tmp_skin.queue_free()
		tmp_skin = $model/Root/Skeleton3D.get_node(material["baju"]["jalur_node"])
		for mtl in tmp_skin.mesh.get_surface_count():
			var tmp_mtl = tmp_s_skin.get_surface_override_material(mtl)
			var tmp_s_mtl = tmp_skin.get_surface_override_material(mtl).duplicate(8)
			tmp_s_mtl.albedo_color = tmp_mtl.albedo_color
			tmp_skin.set_surface_override_material(mtl, tmp_s_mtl)
		tmp_skin.skeleton = NodePath($model/Root/Skeleton3D.get_path())
		tmp_s_skin.queue_free()
	
	if model["sepatu"] != 0:
		var tmp_skin = load("res://karakter/lulu/preset"+str(model["sepatu"])+"/sepatu.scn").instantiate()
		var tmp_s_skin = $model/Root/Skeleton3D.get_node(material["sepatu"]["jalur_node"])
		tmp_skin.name = "sepatu"
		tmp_s_skin.name = "b_sepatu"
		tmp_skin.layers = tmp_s_skin.layers
		$model/Root/Skeleton3D.add_child(tmp_skin.duplicate())
		tmp_skin.queue_free()
		tmp_skin = $model/Root/Skeleton3D.get_node(material["sepatu"]["jalur_node"])
		for mtl in tmp_skin.mesh.get_surface_count():
			var tmp_s_mtl = tmp_s_skin.get_surface_override_material(mtl)
			var tmp_mtl
			if ubah_model["sepatu"] == false:
				tmp_mtl = tmp_skin.mesh.surface_get_material(mtl).duplicate(8)
				ubah_model["sepatu"] = true
			else:
				tmp_mtl = tmp_skin.mesh.surface_get_material(mtl)
			tmp_mtl.albedo_color = tmp_s_mtl.albedo_color
			tmp_skin.set_surface_override_material(mtl, tmp_mtl)
		tmp_s_skin.queue_free()
	else:
		var tmp_skin = load("res://karakter/lulu/sepatu.scn").instantiate()
		var tmp_s_skin = $model/Root/Skeleton3D.get_node(material["sepatu"]["jalur_node"])
		tmp_s_skin.name = "b_sepatu"
		tmp_skin.layers = tmp_s_skin.layers
		$model/Root/Skeleton3D.add_child(tmp_skin.duplicate())
		tmp_skin.queue_free()
		tmp_skin = $model/Root/Skeleton3D.get_node(material["sepatu"]["jalur_node"])
		for mtl in tmp_skin.mesh.get_surface_count():
			var tmp_mtl = tmp_s_skin.get_surface_override_material(mtl)
			var tmp_s_mtl = tmp_skin.get_surface_override_material(mtl).duplicate(8)
			tmp_s_mtl.albedo_color = tmp_mtl.albedo_color
			tmp_skin.set_surface_override_material(mtl, tmp_s_mtl)
		tmp_skin.skeleton = NodePath($model/Root/Skeleton3D.get_path())
		tmp_s_skin.queue_free()
func atur_warna():
	var indeks_material = material.keys()
	for mt in material.size():
		if material[indeks_material[mt]]["jalur_node"] != "":
			var jlr_mtl = material[indeks_material[mt]]["jalur_node"]
			var id_mtl	= material[indeks_material[mt]]["id_material"]
			for mtl in id_mtl.size():
				if get_node_or_null("model/Root/Skeleton3D/"+jlr_mtl) != null:
					var tmp_mtl = $model/Root/Skeleton3D.get_node(jlr_mtl).get_surface_override_material(id_mtl[mtl]).duplicate(8)
					#var n_mtl = StandardMaterial3D.new()
					tmp_mtl.albedo_color = warna[indeks_material[mt]]
					#n_mtl.albedo_texture = tmp_mtl.albedo_texture
					$model/Root/Skeleton3D.get_node(jlr_mtl).set_surface_override_material(id_mtl[mtl], tmp_mtl)
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
