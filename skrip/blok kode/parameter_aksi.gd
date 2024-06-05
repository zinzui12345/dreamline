extends HBoxContainer

func atur_ukuran(skala : float):
	$nama.set("theme_override_font_sizes/font_size", 16 * skala)
	if skala > 1:
		$data.set("theme_override_font_sizes/font_size", 8 * (skala * 1.46))
	else: $data.set("theme_override_font_sizes/font_size", 8)
	$edit.set("theme_override_font_sizes/font_size", 8 * skala)
