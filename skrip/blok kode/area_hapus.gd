extends Panel

const EditorKode = preload("res://skrip/blok kode/editor_kode.gd")

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data.get_parent() != null

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	print("sebelum hapus :")
	print(EditorKode.dapatkan_daftar_kode())
	if data is BlokKode and data.block_id > -1:
		EditorKode.hapus_kode(data.block_id - 1)
		# FIXME : cek rekursif blok di dalam data
		data.queue_free()
	print("setelah hapus :")
	print(EditorKode.dapatkan_daftar_kode())
