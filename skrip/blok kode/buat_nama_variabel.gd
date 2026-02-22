extends LineEdit

func nama_diubah(nama_baru : String) -> void:
	custom_minimum_size.x = clamp((nama_baru.length() * 10) + 10, 68.5, 500)
