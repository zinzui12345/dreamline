extends objek
class_name tombol

@export var jalur_instance : String = ""
@export var ditekan : bool = false :
	set(aktif_):
		atur_ditekan(aktif_)
		ditekan = aktif_
@export var target_entitas : String
@export var nama_fungsi : String

const abaikan_transformasi = true
const properti = [
	["target_entitas", ""],
	["nama_fungsi", ""],
	["ditekan", false]
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

func atur_ditekan(_aktif : bool) -> void:
	pass
