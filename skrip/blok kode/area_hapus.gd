extends Panel

const EditorKode = preload("res://skrip/blok kode/editor_kode.gd")

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data.get_parent() != null

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	print("sebelum hapus :")
	print(EditorKode.dapatkan_daftar_kode())
	# FIXME : daftar_kode jangan Array, karena bergantung sama urutan
	if data is BlokKode and data.block_id > -1:
		EditorKode.hapus_kode(data.block_id - 1)
		if data.body_container.get_child_count() > 0:
			for sub_code in data.body_container.get_children():
				if sub_code is BlokKode:
					EditorKode.hapus_kode(sub_code.block_id - 1)
		data.queue_free()
	print("setelah hapus :")
	print(EditorKode.dapatkan_daftar_kode())
