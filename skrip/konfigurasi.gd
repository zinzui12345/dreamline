extends Node

var sensitivitasPandangan : float = 25.0
var mode_layar_penuh = false
var mode_kontrol_sentuh = false
var mode_kontrol_gerak = "analog"
var skala_kontrol_gerak = 0.8 # TODO : ini untuk ukuran D-Pad dan Analog sentuh
var shader_karakter = false
var volume_musik_latar : float = -3.2 :
	set(volume):
		AudioServer.set_bus_volume_db(1, volume)
		volume_musik_latar = volume
var jarak_render : int = 400

enum bahasa {
	auto,
	indonesia,
	english
}
enum kontrol_gerak {
	analog,
	dpad
}

var kode_bahasa = [
	TranslationServer.get_locale(),
	"id",
	"en"
]
