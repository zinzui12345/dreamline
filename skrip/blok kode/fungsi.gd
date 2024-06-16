extends VBoxContainer
class_name blok_fungsi

var terlipat : bool = false
var ukuran : float = 1.0
var panel_kode : Panel

func tambahkan_aksi(kode : String, jalur_aksi : String = "pemisah_vertikal_2/area_aksi"):
	var instance_aksi
	if kode == "pass":
		instance_aksi = load("res://ui/blok kode/pass.tscn").instantiate()
		get_node(jalur_aksi).add_child(instance_aksi)
		instance_aksi.atur_warna($pemisah_vertikal/nama_fungsi.get_indexed("theme_override_styles/normal:bg_color"))
		instance_aksi.atur_ukuran(ukuran)
	elif kode.match("*(*)") or kode.match("await *(*)*"):
		instance_aksi = load("res://ui/blok kode/aksi.tscn").instantiate()
		# cek kalo aksi_terakhir blok_pass, tukar urutannya
		var aksi_terakhir
		if get_node(jalur_aksi).get_child_count() > 0:
			aksi_terakhir = get_node(jalur_aksi).get_child(get_node(jalur_aksi).get_child_count() - 1)
		if aksi_terakhir is blok_pass:
			get_node(jalur_aksi).remove_child(aksi_terakhir)
			get_node(jalur_aksi).add_child(instance_aksi)
			get_node(jalur_aksi).add_child(aksi_terakhir)
		else:
			get_node(jalur_aksi).add_child(instance_aksi)
			if aksi_terakhir is blok_aksi: aksi_terakhir.cek_urutan()
		instance_aksi.atur_nilai(kode)
		instance_aksi.atur_ukuran(ukuran)
func dapatkan_aksi() -> Array[Node]:
	return $pemisah_vertikal_2/area_aksi.get_children()

func atur_ukuran(skala : float):
	for node in $pemisah_vertikal.get_children():
		node.set(
			"theme_override_font_sizes/font_size",
			20 * skala
		)
	$pemisah_vertikal_2/indentasi.custom_minimum_size.x = 20 * skala
	$pemisah_vertikal/nama_fungsi.set(
		"theme_override_font_sizes/font_size",
		16 * skala
	)
	ukuran = skala
func atur_nama(nama : String):
	$pemisah_vertikal/nama_fungsi.text = nama
func dapatkan_nama() -> String:
	return $pemisah_vertikal/nama_fungsi.text

func lipat():
	for n_blok_aksi in $pemisah_vertikal_2/area_aksi.get_children():
		if terlipat:	n_blok_aksi.visible = true
		else:			n_blok_aksi.visible = false
	if terlipat:
		$pemisah_vertikal/lipat.text = " - "
		terlipat = false
	else:
		$pemisah_vertikal/lipat.text = " / "
		terlipat = true
