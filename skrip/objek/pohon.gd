extends objek

const properti = []

@export var jalur_instance = ""

func mulai() -> void:
	set_process(false)
	set_physics_process(false)
	set("wilayah_render", $lod_1.get_aabb())
