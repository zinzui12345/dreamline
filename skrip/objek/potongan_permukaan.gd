extends objek

const properti = []
const abaikan_occlusion_culling = true

@export var jalur_instance = ""

func mulai() -> void:
	set_process(false)
	set_physics_process(false)
	set("wilayah_render", $bentuk.get_aabb())