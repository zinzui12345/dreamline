extends tombol

@export var ditekan : bool = false :
	set(aktif_):
		atur_ditekan(aktif_)
		ditekan = aktif_

func mulai() -> void:
	atur_ditekan(ditekan)

func fungsikan():
	server.fungsikan_objek(
		name,
		"tekan",
		[
			"entitas_n",
			"nama_fungsi"
		]
	)
	if !ditekan:	aktifkan()
	else:			nonaktifkan()

func tekan(_nama_target_entitas : String, _nama_fungsi : String) -> void:
	$animasi.play("tekan")
func atur_ditekan(aktif : bool) -> void:
	if aktif:
		$frame/transformasi/on.visible = true
		$frame/transformasi/off.visible = false
	else:
		$frame/transformasi/on.visible = false
		$frame/transformasi/off.visible = true
func aktifkan() -> void:
	server.fungsikan_objek(
		name,
		"atur_ditekan",
		[true]
	)
	#set("ditekan", true)
func nonaktifkan() -> void:
	server.fungsikan_objek(
		name,
		"atur_ditekan",
		[false]
	)
	#set("ditekan", false)
