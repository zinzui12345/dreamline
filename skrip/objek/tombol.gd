extends objek
class_name tombol

@export var jalur_instance : String = ""

@export var target_entitas : String
@export var nama_fungsi : String
@export var properti_fungsi : Array

const abaikan_transformasi = true
const properti = [
	["target_entitas", ""],
	["nama_fungsi", ""],
	["properti_fungsi", []]
]

func fungsikan():
	server.fungsikan_objek(
		name,
		"tekan",
		[]
	)
	if target_entitas != "" and nama_fungsi != "":
		server.gunakan_entitas(
			target_entitas,
			nama_fungsi
		)

func tekan():
	$animasi.play("tekan")
