extends Resource

# ----------------------------------------------------------------
@export_group("%setelan_umum")

@export var bahasa := Konfigurasi.bahasa.auto : 
	set(ubah):
		TranslationServer.set_locale(Konfigurasi.kode_bahasa[ubah])
		bahasa = ubah

@export var export_button_mode_layar_penuh := "%mode_layar_penuh"
func mode_layar_penuh():
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	Panku.notify("Fullscreen: " + str(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN))

@export var export_button_tampilkan_log := "%tampilkan_log"
func tampilkan_log():
	var aa = Panku.module_manager.get_module("native_logger")
	aa.open_window()
	#print_debug(aa)

@export var export_button_laporkan_bug := "%laporkan_bug" # Report Bugs
func laporkan_bug():
	#OS.shell_open("https://github.com/Ark2000/PankuConsole/issues")
	print_debug("testt!")

@export var export_button_sarankan_fitur := "%sarankan_fitur"
func sarankan_fitur():
	#OS.shell_open("https://github.com/Ark2000/PankuConsole/issues")
	print_debug("testt!")

# ----------------------------------------------------------------
@export_group("%input")

@export_range(1.0, 80.0) var sensitivitas_gestur := Konfigurasi.sensitivitasPandangan : 
	set(ubah):
		Konfigurasi.sensitivitasPandangan = ubah
		sensitivitas_gestur = ubah
