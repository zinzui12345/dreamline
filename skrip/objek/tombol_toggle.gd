extends tombol

func mulai() -> void:
	atur_ditekan(ditekan)

func fungsikan():
	server.fungsikan_objek(
		name,
		"tekan",
		[]
	)
	if !ditekan:	aktifkan()
	else:			nonaktifkan()

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
func nonaktifkan() -> void:
	server.fungsikan_objek(
		name,
		"atur_ditekan",
		[false]
	)
