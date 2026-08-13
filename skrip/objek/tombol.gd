extends objek

@export var jalur_instance : String = ""

const abaikan_transformasi = true

func fungsikan():
	server.fungsikan_objek(
		name,
		"tekan",
		[
			"entitas_n",
			"nama_fungsi"
		]
	)

func tekan(_nama_target_entitas : String, _nama_fungsi : String):
	$animasi.play("tekan")
