extends Resource

# ----------------------------------------------------------------
@export_group("%setelan_umum")

@export var bahasa := Konfigurasi.bahasa.auto :
	get:
		var kode_bahasa = 0
		match TranslationServer.get_locale():
			"id_ID": kode_bahasa = "indonesia"
			"id": 	 kode_bahasa = "indonesia"
			"en_US": kode_bahasa = "english"
			"en": 	 kode_bahasa = "english"
		return Konfigurasi.bahasa[kode_bahasa]
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

@export var export_button_laporkan_bug := "%laporkan_bug" # Report Bugs
func laporkan_bug(): OS.shell_open("https://github.com/zinzui12345/dreamline/issues")

@export var export_button_sarankan_fitur := "%sarankan_fitur"
func sarankan_fitur(): OS.shell_open("https://t.me/cinta_buatan")

# ----------------------------------------------------------------
@export_group("%input")

@export var kontrol_gerak := Konfigurasi.kontrol_gerak.analog : 
	get:
		return Konfigurasi.kontrol_gerak[Konfigurasi.mode_kontrol_gerak]
	set(ubah):
		server.permainan._ketika_mengubah_mode_kontrol_gerak(ubah)
		kontrol_gerak = ubah

@export_range(1.0, 80.0) var sensitivitas_gestur := Konfigurasi.sensitivitasPandangan : 
	set(ubah):
		Konfigurasi.sensitivitasPandangan = ubah
		sensitivitas_gestur = ubah

# ----------------------------------------------------------------
@export_group("Debug")

@export var informasi_performa : bool = false:
	get:
		return server.permainan.get_node("performa").visible
		return server.permainan.get_node("versi").visible
	set(v):
		server.permainan.get_node("performa").visible = v
		server.permainan.get_node("versi").visible = v

@export var export_button_tampilkan_log := "%tampilkan_log"
func tampilkan_log():
	var aa = Panku.module_manager.get_module("native_logger")
	aa.open_window()

@export var export_button_tampilkan_konsol := "%tampilkan_konsol"
func tampilkan_konsol(): Panku.toggle_console_action_just_pressed.emit()
