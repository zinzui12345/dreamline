extends VBoxContainer
class_name blok_kondisi

var nilai : String = ""
var urutan : int = -1
var node_induk : Control
var node_fungsi : blok_fungsi
var id_kondisi : int = 0
var sub_kondisi : bool
var terlipat : bool = false

func cek_urutan() -> void:
	if urutan == -1:
		for id_cek_urutan in get_parent().get_child_count():
			if get_parent().get_child(id_cek_urutan) == self:
				urutan = id_cek_urutan
				break
	if node_induk is blok_fungsi:
		if urutan == 0:
			$pemisah_vertikal/geser_keatas.disabled = true
			if urutan == (get_parent().get_child_count() - 1):
				$pemisah_vertikal/geser_kebawah.disabled = true
			elif urutan == (get_parent().get_child_count() - 2) and !sub_kondisi and get_parent().get_child(urutan + 1) is blok_kondisi and get_parent().get_child(urutan + 1).id_kondisi == self.id_kondisi:
				$pemisah_vertikal/geser_kebawah.disabled = true
			else:
				$pemisah_vertikal/geser_kebawah.disabled = false
		elif urutan == (get_parent().get_child_count() - 2) and get_parent().get_child(urutan + 1) is blok_pass:
			$pemisah_vertikal/geser_keatas.disabled = false
			$pemisah_vertikal/geser_kebawah.disabled = true
			get_parent().get_child(urutan - 1).cek_urutan()
		elif urutan == (get_parent().get_child_count() - 2) and !sub_kondisi and get_parent().get_child(urutan + 1) is blok_kondisi and get_parent().get_child(urutan + 1).id_kondisi == self.id_kondisi:
			$pemisah_vertikal/geser_keatas.disabled = false
			$pemisah_vertikal/geser_kebawah.disabled = true
		elif urutan == (get_parent().get_child_count() - 1):
			$pemisah_vertikal/geser_kebawah.disabled = true
			get_parent().get_child(urutan - 1).cek_urutan()
		else:
			$pemisah_vertikal/geser_keatas.disabled = false
			$pemisah_vertikal/geser_kebawah.disabled = false
			if sub_kondisi: get_parent().get_child(urutan - 1).cek_urutan()
func geser_keatas() -> void:
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
		if urutan < get_parent().get_child_count() - 2:
			var aksi_3 = get_parent().get_child(urutan + 2)
			if aksi_3 is blok_kondisi and aksi_3.id_kondisi == aksi_2.id_kondisi and aksi_3.sub_kondisi:
				aksi_3.geser_keatas()
func geser_kebawah() -> void:
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
		if urutan < get_parent().get_child_count() - 1:
			var aksi_3 = get_parent().get_child(urutan - 1)
			if aksi_3 is blok_kondisi and aksi_3.id_kondisi == aksi_1.id_kondisi and aksi_3.sub_kondisi:
				aksi_1.geser_kebawah()
				aksi_3.geser_kebawah()
				aksi_3.geser_kebawah()
		#elif aksi_1.sub_kondisi:
			#print_debug("punya gelar S3 IT tapi gak bisa ngoding, chuakkks!")
			#get_parent().get_child(urutan - 1).cek_urutan()

func atur_ukuran(skala : float) -> void:
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
func atur_nilai(t_nilai : String) -> void:
	nilai = t_nilai
	if t_nilai == "else:": t_nilai = "%kondisi_lain"
	if node_fungsi.get("panel_kode") != null and node_fungsi.panel_kode.get("tipe_kode") != null:
		#print_debug("tak perlu tunggu tunggu hebat, untuk berani memulai apa yang kau impikan~")
		# INFO : terjemahkan teks kondisi
		match node_fungsi.panel_kode.tipe_kode + '>' + t_nilai:
			"pintu>if get_node(\"../../\").kondisi:":	t_nilai = "%kondisi_pintu_terbuka"
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

func tambahkan_aksi(kode : String) -> void:
	if node_fungsi != null:
		node_fungsi.tambahkan_aksi(kode, str(node_fungsi.get_path_to(self)) + "/pemisah_vertikal_2/area_aksi")
func dapatkan_aksi(pilih_urutan) -> Control:
	return $pemisah_vertikal_2/area_aksi.get_child(pilih_urutan)

func lipat() -> void:
	for n_blok_aksi in $pemisah_vertikal_2/area_aksi.get_children():
		if terlipat:	n_blok_aksi.visible = true
		else:			n_blok_aksi.visible = false
	if terlipat:
		$pemisah_vertikal/lipat.text = " - "
		terlipat = false
	else:
		$pemisah_vertikal/lipat.text = " / "
		terlipat = true
