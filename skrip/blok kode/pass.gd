extends Label
class_name blok_pass

func atur_ukuran(skala : float):
	set(
		"theme_override_font_sizes/font_size",
		16 * skala
	)
func atur_warna(warna : Color):
	set_indexed("theme_override_styles/normal:bg_color", warna)
