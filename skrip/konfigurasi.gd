extends Node

var data_konfigurasi : String = "user://konfigurasi.dreamline"
var data_pemain : String = "user://data.dreamline"
var direktori_aset : String = "user://aset"
var data_aset : String = direktori_aset + "/daftar_aset.dreamline"
var bahasa : int = 0 :
	set(pilih):
		TranslationServer.set_locale(kode_bahasa[pilih])
		bahasa = pilih
var sensitivitasPandangan : float = 25.0
var mode_layar_penuh : bool = false :
	set(nilai):
		if nilai:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
			mode_layar_penuh = nilai
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			mode_layar_penuh = nilai
var mode_kontrol_sentuh : bool = false
var mode_kontrol_gerak : int = 0
var skala_kontrol_gerak : float = 0.8 # TODO : ini untuk ukuran D-Pad dan Analog sentuh
var shader_karakter : bool = false
var volume_musik_latar : float = -3.2 :
	set(volume):
		AudioServer.set_bus_volume_db(1, volume)
		volume_musik_latar = volume
var jarak_render : int = 400

enum pilih_bahasa {
	auto,
	english,
	indonesia
}

var kode_bahasa : Array[StringName] = [
	TranslationServer.get_locale(),
	"en",
	"id"
]

func muat() -> void:
	if !FileAccess.file_exists(data_konfigurasi):
		#Panku.notify("Tidak ada file konfigurasi yang ditemukan")
		#Panku.notify("Membuat file konfigurasi")
		simpan()
	else:
		Panku.notify("%muat_pengaturan")
	
	var file : FileAccess = FileAccess.open(data_konfigurasi, FileAccess.READ)
	var data = file.get_var()
	
	if data != null and data is Dictionary:
		if data.get("bahasa") != null:						bahasa = data["bahasa"]
		if data.get("mode_layar_penuh") != null:			mode_layar_penuh = data["mode_layar_penuh"]
		
		if data.get("mode_kontrol_gerak") != null:			mode_kontrol_gerak = data["mode_kontrol_gerak"]
		if data.get("skala_kontrol_gerak") != null:			skala_kontrol_gerak = data["skala_kontrol_gerak"]
		if data.get("sensitivitas_pandangan") != null:		sensitivitasPandangan = data["sensitivitas_pandangan"]
		
		if data.get("jarak_render") != null:				jarak_render = data["jarak_render"]
		if data.get("shader_karakter") != null:				shader_karakter = data["shader_karakter"]
		
		if data.get("volume_musik_latar") != null:			volume_musik_latar = data["volume_musik_latar"]
	else: simpan()
	file.close()
func simpan() -> void:
	var file : FileAccess = FileAccess.open(data_konfigurasi, FileAccess.WRITE)
	var data : Dictionary = {
		"bahasa"				: bahasa,
		"mode_layar_penuh"		: mode_layar_penuh,
		
		"mode_kontrol_gerak"	: mode_kontrol_gerak,
		"skala_kontrol_gerak"	: skala_kontrol_gerak,
		"sensitivitas_pandangan": sensitivitasPandangan,
		
		"jarak_render"			: jarak_render,
		"shader_karakter"		: shader_karakter,
		
		"volume_musik_latar"	: volume_musik_latar
	}
	
	file.store_var(data)
	file.close()
	
	Panku.notify("%simpan_pengaturan")
