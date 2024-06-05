extends VBoxContainer
class_name blok_kondisi

var nilai : String = ""
var urutan : int = -1
var node_induk : Control
var node_fungsi : blok_fungsi
var terlipat : bool = false

func cek_urutan():
	if urutan == -1:
		for id_cek_urutan in get_parent().get_child_count():
			if get_parent().get_child(id_cek_urutan) == self:
				urutan = id_cek_urutan
				break
	if node_induk is blok_fungsi:
		if urutan == 0:
			$pemisah_vertikal/geser_keatas.disabled = true
		elif urutan == (get_parent().get_child_count() - 2) and get_parent().get_child(urutan + 1) is blok_pass:
			$pemisah_vertikal/geser_kebawah.disabled = true
			get_parent().get_child(urutan - 1).cek_urutan()
		elif urutan == (get_parent().get_child_count() - 1):
			$pemisah_vertikal/geser_kebawah.disabled = true
			get_parent().get_child(urutan - 1).cek_urutan()
		else:
			$pemisah_vertikal/geser_keatas.disabled = false
			$pemisah_vertikal/geser_kebawah.disabled = false
func geser_keatas():
	if urutan > 0:
		# dapatkan node blok aksi
		var aksi_1 = get_parent().get_child(urutan - 1)
		var aksi_2 = self
		# dapatkan urutan aksi
		var urutan_aksi_1 = aksi_1.urutan
		var urutan_aksi_2 = urutan
		# tukar urutan aksi
		get_parent().move_child(aksi_1, urutan_aksi_2)
		get_parent().move_child(aksi_2, urutan_aksi_1)
		# perbarui urutan aksi
		var tmp_urtan_aksi_1 = urutan_aksi_1
		aksi_1.urutan = urutan_aksi_2
		aksi_2.urutan = tmp_urtan_aksi_1
		aksi_1.cek_urutan()
		aksi_2.cek_urutan()
func geser_kebawah():
	if urutan < get_parent().get_child_count() - 1:
		# dapatkan node blok aksi
		var aksi_1 = self
		var aksi_2 = get_parent().get_child(urutan + 1)
		# dapatkan urutan aksi
		var urutan_aksi_1 = urutan
		var urutan_aksi_2 = aksi_2.urutan
		# tukar urutan aksi
		get_parent().move_child(aksi_1, urutan_aksi_2)
		get_parent().move_child(aksi_2, urutan_aksi_1)
		# perbarui urutan aksi
		var tmp_urtan_aksi_1 = urutan_aksi_1
		aksi_1.urutan = urutan_aksi_2
		aksi_2.urutan = tmp_urtan_aksi_1
		aksi_1.cek_urutan()
		aksi_2.cek_urutan()

func atur_ukuran(skala : float):
	$pemisah_vertikal/nilai_kondisi.set(
		"theme_override_font_sizes/font_size",
		16 * skala
	)
	$pemisah_vertikal/geser_keatas.set(
		"theme_override_font_sizes/font_size",
		20 * skala
	)
	$pemisah_vertikal/geser_kebawah.set(
		"theme_override_font_sizes/font_size",
		20 * skala
	)
	$pemisah_vertikal/lipat.set(
		"theme_override_font_sizes/font_size",
		20 * skala
	)
	$pemisah_vertikal_2/indentasi.custom_minimum_size.x = 20 * skala
	# 24/05/24
	# there's a party with a real cake, yes it's real
	# the cake i made
	# talking and FUN
	# testing and Fun
	# all of this fun! without you!
	for b_blok_aksi in $pemisah_vertikal_2/area_aksi.get_children():
		if b_blok_aksi.has_method("atur_ukuran"):
			b_blok_aksi.atur_ukuran(skala)
func atur_nilai(t_nilai : String):
	nilai = t_nilai
	$pemisah_vertikal/nilai_kondisi.text = " "+t_nilai
func dapatkan_nilai() -> String:
	return nilai
func dapatkan_nilai_aksi() -> Array[String]:
	var daftar_aksi : Array[String] = []
	for aksi in $pemisah_vertikal_2/area_aksi.get_children():
		if aksi is blok_aksi: daftar_aksi.append("\t" + aksi.dapatkan_nilai())
		if aksi is blok_pass: daftar_aksi.append("\tpass")
		if aksi is blok_kondisi:
			daftar_aksi.append("\t" + aksi.dapatkan_nilai())
			for b_aksi in aksi.dapatkan_nilai_aksi():
				daftar_aksi.append("\t" + b_aksi)
	return daftar_aksi

func tambahkan_aksi(kode : String):
	if node_fungsi != null:
		node_fungsi.tambahkan_aksi(kode, str(node_fungsi.get_path_to(self)) + "/pemisah_vertikal_2/area_aksi")

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
