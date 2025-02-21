# 01/02/25
extends objek
class_name placeholder_objek

# Attach skrip ini ke skena objek dengan kode_ubahan yang ditambahkan ke map
# kode ubahan mewarisi kelas objek (block_script.script_inherits = "objek")
# atur extends pada generated_script kode_ubahan menjadi kelas ini (placeholder_objek)
# sesuaikan properti jalur_instance pada objek

@export var jalur_instance = "res://skena/objek/placeholder_objek.tscn"

func _ready() -> void:
	if process_mode == PROCESS_MODE_DISABLED and get_parent().process_mode == PROCESS_MODE_DISABLED: return
	else: call_deferred("_setup")
