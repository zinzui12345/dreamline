extends Node

var sensitivitasPandangan : float = 25.0
var mode_layar_penuh = false
var mode_kontrol_sentuh = false
var skala_kontrol_gerak = 0.8 # TODO : ini untuk ukuran D-Pad dan Analog sentuh

enum bahasa {
	auto,
	indonesia,
	english
}
var kode_bahasa = [
	TranslationServer.get_locale(),
	"id",
	"en"
]
