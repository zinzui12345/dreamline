extends entitas

const radius_tabrak : int = 10
const sinkron_kondisi = [
	["warna_1", Color("FFF")],
	["warna_2", Color("3900ff")],
	["warna_3", Color("ff0021")],
	["warna_4", Color("ff5318")],
	["warna_5", Color("000000")]
]
const jalur_instance = "res://skena/entitas/bajay.tscn"

var mat1 : StandardMaterial3D
var mat2 : StandardMaterial3D
var mat3 : StandardMaterial3D
var mat4 : StandardMaterial3D
var mat5 : StandardMaterial3D

var warna_1 : Color :
	set(ubah_warna):
		if mat1 != null: mat1.albedo_color = ubah_warna
		warna_1 = ubah_warna
var warna_2 : Color :
	set(ubah_warna):
		if mat2 != null: mat2.albedo_color = ubah_warna
		warna_2 = ubah_warna
var warna_3 : Color :
	set(ubah_warna):
		if mat3 != null: mat3.albedo_color = ubah_warna
		warna_3 = ubah_warna
var warna_4 : Color :
	set(ubah_warna):
		if mat4 != null: mat4.albedo_color = ubah_warna
		warna_4 = ubah_warna
var warna_5 : Color :
	set(ubah_warna):
		if mat5 != null: mat5.albedo_color = ubah_warna
		warna_5 = ubah_warna

# fungsi yang akan dipanggil pada saat node memasuki SceneTree menggantikan _ready()
func mulai() -> void:
	mat1 = $model/detail/bodi.get_surface_override_material(0).duplicate()
	mat2 = $model/detail/bodi.get_surface_override_material(1).duplicate()
	mat3 = $model/detail/bodi.get_surface_override_material(10).duplicate()
	mat4 = $model/detail/bodi.get_surface_override_material(5).duplicate()
	mat5 = $model/detail/bodi.get_surface_override_material(11).duplicate()
	warna_1 = warna_1
	warna_2 = warna_2
	warna_3 = warna_3
	warna_4 = warna_4
	warna_5 = warna_5
	$model/detail/bodi.set_surface_override_material(0, mat1)
	$model/detail/bodi.set_surface_override_material(1, mat2)
	$model/detail/bodi.set_surface_override_material(10, mat3)
	$model/detail/bodi.set_surface_override_material(5, mat4)
	$model/detail/bodi.set_surface_override_material(11, mat5)
	$model/detail/subreker_depan.set_surface_override_material(0, mat5)
# fungsi yang akan dipanggil setiap saat menggantikan _process(delta)
func proses(_waktu_delta : float) -> void:
	pass
