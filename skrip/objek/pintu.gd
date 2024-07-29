extends objek
class_name pintu

const abaikan_occlusion_culling = true
const properti = [
	["warna_1", Color("00FF00")],
	["kondisi", false],
	["kode", "func gunakan():\n\tif get_node(\"../../\").kondisi:\n\t\tget_node(\"../../\").tutup()\n\telse:\n\t\tget_node(\"../../\").buka()"]
]

@export var jalur_instance : String = ""
@export var kondisi : bool = false :
	set(terbuka):
		if _telah_spawn:
			if terbuka:	$animasi.play("buka")
			else:		$animasi.play("tutup")
		kondisi = terbuka
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
	$kode_ubahan.atur_kode(properti[2][1])
	if kondisi:	$animasi.play("terbuka")
	else:		$animasi.play("tertutup")
	_telah_spawn = true

func terapkan_warna(warnanya : Color) -> void:
	if get_node_or_null("engsel/pintu/detail") != null:
		if material_pintu_detail == null:
			material_pintu_detail = $engsel/pintu/detail.get_surface_override_material(0).duplicate()
			material_pintu_lod = $engsel/pintu/lod.get_surface_override_material(0).duplicate()
			$engsel/pintu/detail.set_surface_override_material(0, material_pintu_detail)
			$engsel/pintu/lod.set_surface_override_material(0, material_pintu_lod)
		
		_warna_pintu = warnanya
		material_pintu_detail.set("albedo_color", _warna_pintu)
		material_pintu_lod.set("albedo_color", _warna_pintu)

func buka() -> void:
	if not kondisi:
		$animasi.play("buka")
		server.fungsikan_objek(
			name,
			"buka",
			[]
		)
		set("kondisi", true)
func tutup() -> void:
	if kondisi:
		$animasi.play("tutup")
		server.fungsikan_objek(
			name,
			"tutup",
			[]
		)
		set("kondisi", false)
