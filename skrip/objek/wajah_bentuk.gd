extends MeshInstance3D

@export var unik : bool = false
@export var objek_bentuk : Node3D
@export var indeks_wajah : int

func _ready() -> void:
	if objek_bentuk != null and not objek_bentuk.wajah.has(name):
		indeks_wajah = objek_bentuk.wajah.size()
		objek_bentuk.wajah.append(name)

func atur_material(material : Material) -> void:
	mesh.material = material

func dapatkan_material() -> Material:
	if mesh.material != null:
		if not unik:
			return mesh.material
		else:
			var normal_material : Material = mesh.material.duplicate()
			normal_material.uv1_scale.x = 1.0
			normal_material.uv1_scale.y = 1.0
			return normal_material
	return null

func atur_skala_material(skala : Vector2) -> void:
	if mesh.material != null:
		if not unik:
			atur_material(mesh.material.duplicate())
			unik = true
		mesh.material.uv1_scale.x = skala.x
		mesh.material.uv1_scale.y = skala.y
