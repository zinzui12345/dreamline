# 01/02/25
extends npc_ai
class_name placeholder_npc_ai

# Attach skrip ini ke skena npc_ai dengan kode_ubahan yang ditambahkan ke map
# kode ubahan mewarisi kelas npc_ai (block_script.script_inherits = "npc_ai")
# atur extends pada generated_script kode_ubahan menjadi kelas ini (placeholder_npc_ai)
# sesuaikan properti jalur_instance pada npc_ai

@export var jalur_instance = ""

func _ready() -> void:
	if process_mode == PROCESS_MODE_DISABLED and get_parent().process_mode == PROCESS_MODE_DISABLED: return
	else: call_deferred("_setup")
