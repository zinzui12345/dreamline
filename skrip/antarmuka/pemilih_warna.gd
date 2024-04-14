extends Control

# i create a bunch of button with different names as child of Node2D in godot, create gdscript code to emit signal for button name which pressed
signal warna_dipilih(warna : Color)

func atur_penyesuaian_warna(warna : Color): $kolom_warna/sesuaikan.color = warna

func _on_button_pressed(nilai_warna):
	var tmp_warna = str(nilai_warna)
	$kolom_warna/sesuaikan.color = Color(nilai_warna)
	emit_signal("warna_dipilih", tmp_warna)
func _ketika_mengubah_warna(warna):
	var tmp_warna = warna.to_html(false)
	#print_debug(tmp_warna)
	emit_signal("warna_dipilih", tmp_warna)

func _ready():
	for button in $kolom_warna.get_children():
		if button is ColorPickerButton: pass
		elif button is Button:
			var button_name = button.get_name()
			var picker = Callable(self, "_on_button_pressed")
			button.connect("pressed", picker.bind(button_name))
