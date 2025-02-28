extends placeholder_objek
#class_name patung

#const jalur_instance = "res://skena/objek/patung_moai.scn"

func mulai() -> void:
	set_process(false)
	set_physics_process(false)
	set("wilayah_render", $bentuk.get_aabb())
