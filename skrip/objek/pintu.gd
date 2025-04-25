extends objek
class_name pintu

const abaikan_occlusion_culling = true

@export var jalur_instance : String = ""
@export var terbuka : bool = false :
	set(terbuka_):
		if _telah_spawn:
			if terbuka:	$animasi.play("buka")
			else:		$animasi.play("tutup")
		terbuka = terbuka_
@export var warna_1 : Color = Color("#00ff00") :
	set(warna_baru):
		terapkan_warna(warna_baru)
		warna_1 = warna_baru
@export var material_pintu_detail : StandardMaterial3D
@export var material_pintu_lod : StandardMaterial3D

var _warna_pintu : Color
var _telah_spawn : bool

func mulai() -> void:
	set("wilayah_render", $area_render.get_aabb())
	terapkan_warna(warna_1)
	if terbuka:	$animasi.play("terbuka")
	else:		$animasi.play("tertutup")
	_telah_spawn = true

func terapkan_warna(warnanya : Color) -> void:
	if get_node_or_null("engsel/pintu/detail") != null:
		# 20/11/24 :: terapkan ulang material jika kode diubah
		if material_pintu_detail != null and material_pintu_detail.get_rid() != $engsel/pintu/detail.get_surface_override_material(0).get_rid():
			material_pintu_detail = null
			material_pintu_lod = null
		
		if material_pintu_detail == null:
			material_pintu_detail = $engsel/pintu/detail.get_surface_override_material(0).duplicate() if $engsel/pintu/detail.get_surface_override_material(0) != null else StandardMaterial3D.new()
			material_pintu_lod = $engsel/pintu/lod.get_surface_override_material(0).duplicate() if $engsel/pintu/lod.get_surface_override_material(0) != null else StandardMaterial3D.new()
			$engsel/pintu/detail.set_material_override(material_pintu_detail)
			$engsel/pintu/lod.set_material_override(material_pintu_lod)
		
		_warna_pintu = warnanya
		material_pintu_detail.set("albedo_color", _warna_pintu)
		material_pintu_lod.set("albedo_color", _warna_pintu)

func buka() -> void:
	if not terbuka and not $fisik.disabled:
		$animasi.play("buka")
		server.fungsikan_objek(
			name,
			"buka",
			[]
		)
		set("terbuka", true)
func tutup() -> void:
	if terbuka and not $fisik.disabled:
		$animasi.play("tutup")
		server.fungsikan_objek(
			name,
			"tutup",
			[]
		)
		set("terbuka", false)

func fungsikan():
	if !terbuka:
		buka()
	else:
		tutup()

static func get_custom_class() -> String:
	return "pintu"
