extends Node3D
class_name kode_ubahan

@export var kode : String = "func placeholder():\n\tPanku.notify(\"ini adalah contoh kode\")\n\tpass"

func dapatkan_kode() -> String:
	return kode

func atur_kode(kode : String):
	# compile kode ke komponen GDScript
	# set self.kode dengan kode
	pass
