extends objek

const properti : Array = [["warna_1", Color("#00ff00")]]

@export var jalur_instance = ""
@export var warna_1 : Color = Color("#00ff00") :
	set(warna_baru):
		terapkan_warna(warna_baru)
		warna_1 = warna_baru
@export var material_daun_detail : StandardMaterial3D
@export var material_daun_lod1 : Material
@export var material_daun_lod2 : Material

var _warna_daun : Color

func mulai() -> void:
	set_process(false)
	set_physics_process(false)
	set("wilayah_render", $detail/batang.get_aabb())
	terapkan_warna(warna_1)

func terapkan_warna(warnanya : Color) -> void:
	if get_node_or_null("detail/daun") != null:
		if material_daun_detail == null:
			material_daun_detail = $detail/daun.get_surface_override_material(0).duplicate()
			material_daun_lod1 = $lod_1/daun.get_surface_override_material(0).duplicate()
			material_daun_lod2 = $lod_2/daun.get_surface_override_material(0).duplicate()
			$detail/daun.set_surface_override_material(0, material_daun_detail)
			$lod_1/daun.set_surface_override_material(0, material_daun_lod1)
			$lod_2/daun.set_surface_override_material(0, material_daun_lod2)
		
		_warna_daun = warnanya
		material_daun_detail.set("albedo_color", _warna_daun)
		material_daun_lod1.set("albedo_color", _warna_daun)
		material_daun_lod2.set("albedo_color", _warna_daun)
