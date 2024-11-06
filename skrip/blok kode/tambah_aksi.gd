extends Button 

@export var kode : String

func _ready():
	connect("pressed", _tekan) # FIXME : kenapa signalnya sama satu dengan yang lain pas awal???

func _tekan():
	# "../../../../.." asumsi kalo posisi tombol selalu di dalam menu
	$"../../..".button_pressed = false
	$"../../../../..".tambah_blok_aksi(kode)
