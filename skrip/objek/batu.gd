extends objek

const properti = []

@export var jalur_instance = ""

func mulai():
	set_process(false)
	set_physics_process(false)
	set("wilayah_render", $bentuk.get_aabb())
