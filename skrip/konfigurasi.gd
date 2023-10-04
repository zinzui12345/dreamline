extends Node

var sensitivitasPandangan : float = 25.0
var mode_layar_penuh = false
var mode_kontrol_sentuh = false
var mode_kontrol_gerak = "analog"
var skala_kontrol_gerak = 0.8 # TODO : ini untuk ukuran D-Pad dan Analog sentuh
var shader_karakter = false

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
