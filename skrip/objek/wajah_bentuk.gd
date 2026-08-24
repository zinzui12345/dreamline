extends MeshInstance3D

@export var objek_bentuk : Node3D
@export var indeks_wajah : int

func _ready() -> void:
	if objek_bentuk != null and not objek_bentuk.wajah.has(name):
		indeks_wajah = objek_bentuk.wajah.size()
		objek_bentuk.wajah.append(name)
