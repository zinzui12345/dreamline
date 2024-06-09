extends Button
class_name blok_aksi

var urutan = -1
var node_induk : Control
var fungsi : Array[String] = []
var parameter : String = ""

func _ready():
	node_induk = get_parent().get_parent().get_parent()
	cek_urutan()
	name = "aksi_" + str(urutan + 1)

func atur_nilai(nilai : String):
	nilai = nilai.reverse()
	fungsi.clear()
	var pecah_nilai = nilai.split("(", true, 1)
	var pecah_parameter = pecah_nilai[0].split(")", true, 1)
	var nama_fungsi = ""
	# cek deklarasi tipe data pada parameter
	if pecah_nilai[1].count("(") > 0 and pecah_nilai[1].count(")") < pecah_nilai[1].count("("):
		var indeks_posisi = 0
		for n in pecah_nilai[1].count("("):
			var tmp_p = pecah_parameter[1]
			pecah_parameter[1] = "(" + pecah_nilai[1].substr(0, pecah_nilai[1].find("(", indeks_posisi))
			tmp_p += pecah_parameter[1]
			pecah_parameter[1] = tmp_p
			var tmp_indeks_posisi = pecah_nilai[1].find("(", indeks_posisi)
			pecah_nilai[1] = pecah_nilai[1].substr(pecah_nilai[1].find("(", indeks_posisi) + 1)
			indeks_posisi = tmp_indeks_posisi
	var s_fungsi = pecah_nilai[1].reverse()
	fungsi.append(pecah_nilai[1].reverse() + "(")
	fungsi.append(")" + pecah_parameter[0].reverse())
	parameter = pecah_parameter[1].reverse()
	# cek fungsi
	if s_fungsi == "Panku.notify":
		nama_fungsi = " notifikasi(x)"
		set("theme_override_styles/normal", load("res://ui/blok kode/warna/notifikasi.stylebox"))
	elif s_fungsi.match("await *"):
		if s_fungsi == "await get_tree().create_timer" and pecah_parameter[0].reverse() == ".timeout":
			nama_fungsi = " tunggu(x)"
		else:
			nama_fungsi = " tunggu : " + s_fungsi.split(" ")[1] + "(x)"
			if pecah_parameter[0] != "":
				nama_fungsi += pecah_parameter[0].reverse()
		set("theme_override_styles/normal", load("res://ui/blok kode/warna/tunda.stylebox"))
	else:
		nama_fungsi = " " + s_fungsi
		if pecah_parameter[1] != null and pecah_parameter[1] != "":
			nama_fungsi += "(x)"
		else:
			nama_fungsi += "()"
		if pecah_parameter[0] != "":
			nama_fungsi += pecah_parameter[0].reverse()
		set("theme_override_styles/normal", load("res://ui/blok kode/warna/aksi.stylebox"))
	$pemisah_vertikal/data_aksi/nama_fungsi.text = nama_fungsi
	$pemisah_vertikal/data_aksi/nama_fungsi_n.text = nama_fungsi
	$pemisah_vertikal/data_aksi/parameter/data.text = "[" + parameter + "]"
	if parameter == "":
		$pemisah_vertikal/data_aksi/parameter.visible = false
		$pemisah_vertikal/data_aksi/nama_fungsi.visible = false
		$pemisah_vertikal/data_aksi/nama_fungsi_n.visible = true
	else:
		$pemisah_vertikal/data_aksi/nama_fungsi_n.visible = false
		$pemisah_vertikal/data_aksi/parameter.visible = true
		$pemisah_vertikal/data_aksi/nama_fungsi.visible = true
func dapatkan_nilai() -> String:
	return self.fungsi[0] + parameter + self.fungsi[1]
func edit_nilai():
	if node_induk != null:
		var pecah_parameter = parameter.split(",")
		var gabung_parameter = ""
		var sub_fungsi = false
		for p in pecah_parameter:
			if p.substr(0, 1) == " ": p = p.substr(1)
			if p.substr(0, 1) == " ": p = p.substr(1)
			if gabung_parameter.length() > 0: gabung_parameter += ", "
			if p.match("Vector3(*") or p.match("Vector2(*"):
				gabung_parameter += "{\"tipe_data\": \"" + p.substr(0, 7) + "\", \"data\":[" + p.substr(8)
				sub_fungsi = true
			elif p.match("Color(*)"):
				gabung_parameter += "{\"tipe_data\": \"" + p.substr(0, 5) + "\", \"data\":[" + p.substr(6, p.length() - 7) + "]}"
			elif p.substr(p.length() - 1) == ")" and sub_fungsi:
				gabung_parameter += p.substr(0, p.length() - 1) + "]}"
				sub_fungsi = false
			else: gabung_parameter += p
		#print_debug(gabung_parameter)
		var tmp_parameter = JSON.parse_string("{\"parameter\": ["+gabung_parameter+"]}")
		#print_debug(str(tmp_parameter) + " << " + parameter)
		#print_debug(type_string(typeof(tmp_parameter["parameter"])))
		var nilai_parameter : Array = []
		for pp in tmp_parameter["parameter"]:
			if pp is Dictionary and pp.size() == 2 and pp.has("tipe_data"):
				if pp["tipe_data"] == "Vector2":
					nilai_parameter.append(Vector2(pp["data"][0], pp["data"][1]))
				elif pp["tipe_data"] == "Vector3":
					nilai_parameter.append(Vector3(pp["data"][0], pp["data"][1], pp["data"][2]))
				elif pp["tipe_data"] == "Color":
					nilai_parameter.append(Color(pp["data"][0]))
					#print_debug("'half,blue'")
					#print_debug(pp["data"][0])
			elif pp is float and !str(pp).contains("."):
				nilai_parameter.append(int(pp))
			else:
				nilai_parameter.append(pp)
		#print_debug(nilai_parameter)
		if node_induk is blok_fungsi:
			node_induk.panel_kode.ubah_nilai_aksi(self.get_path(), fungsi, nilai_parameter)
		elif node_induk is blok_kondisi:
			node_induk.node_fungsi.panel_kode.ubah_nilai_aksi(self.get_path(), fungsi, nilai_parameter)
func atur_ukuran(skala : float):
	set(
		"theme_override_font_sizes/font_size",
		32 * skala
	)
	# data aksi
	$pemisah_vertikal/data_aksi/nama_fungsi.set(
		"theme_override_font_sizes/font_size",
		12 * skala
	)
	$pemisah_vertikal/data_aksi/nama_fungsi_n.set(
		"theme_override_font_sizes/font_size",
		22 * skala
	)
	$pemisah_vertikal/data_aksi/parameter.atur_ukuran(skala)
	# tombol edit
	$pemisah_vertikal/geser_keatas.set(
		"theme_override_font_sizes/font_size",
		24 * skala
	)
	$pemisah_vertikal/geser_kebawah.set(
		"theme_override_font_sizes/font_size",
		24 * skala
	)
	$pemisah_vertikal/hapus.set(
		"theme_override_font_sizes/font_size",
		24 * skala
	)

func cek_urutan():
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
			else:
				$pemisah_vertikal/geser_kebawah.disabled = false
		elif urutan == (get_parent().get_child_count() - 2) and get_parent().get_child(urutan + 1) is blok_pass:
			$pemisah_vertikal/geser_keatas.disabled = false
			$pemisah_vertikal/geser_kebawah.disabled = true
			get_parent().get_child(urutan - 1).cek_urutan()
		elif urutan == (get_parent().get_child_count() - 1):
			if get_parent().get_child(urutan - 1) != self:
				get_parent().get_child(urutan - 1).cek_urutan()
				$pemisah_vertikal/geser_kebawah.disabled = true
			else:
				$pemisah_vertikal/geser_kebawah.disabled = false
		else:
			$pemisah_vertikal/geser_keatas.disabled = false
			$pemisah_vertikal/geser_kebawah.disabled = false
func geser_keatas():
	# dapatkan node blok aksi
	var aksi_1 = get_parent().get_child(urutan - 1)
	var aksi_2 = self
	# cek arah tukar
	if urutan > 0:
		if aksi_1 is blok_kondisi:
			aksi_1.tambahkan_aksi(aksi_2.dapatkan_nilai())
			aksi_2.hapus()
			if aksi_1.terlipat: aksi_1.lipat()
		else:
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
	elif node_induk is blok_kondisi:
		#print_debug("i will be waiting")
		node_induk.node_fungsi.panel_kode.pilih_scope = node_induk.node_induk
		if node_induk.urutan > 0:
			node_induk.node_fungsi.panel_kode.pilih_aksi = node_induk.get_parent().get_child(node_induk.urutan - 1)
			node_induk.node_fungsi.panel_kode.tambah_blok_aksi(aksi_2.dapatkan_nilai())
		else:
			node_induk.node_fungsi.panel_kode.pilih_aksi = node_induk
			node_induk.node_fungsi.panel_kode.tambah_blok_aksi(aksi_2.dapatkan_nilai())
			node_induk.geser_kebawah()
		aksi_2.hapus()
func geser_kebawah():
	# dapatkan node blok aksi
	var aksi_1 = self
	# cek arah tukar
	if urutan < get_parent().get_child_count() - 1 and !(get_parent().get_child(urutan + 1) is blok_pass):
		# dapatkan node blok aksi
		var aksi_2 = get_parent().get_child(urutan + 1)
		# cek arah tukar
		if aksi_2 is blok_kondisi:
			if aksi_2.dapatkan_aksi(0) != null and !(aksi_2.dapatkan_aksi(0) is blok_pass):
				 # atur ke urutan pertama
				aksi_2.node_fungsi.panel_kode.pilih_scope = aksi_2
				aksi_2.node_fungsi.panel_kode.pilih_aksi = aksi_2.dapatkan_aksi(0)
				aksi_2.node_fungsi.panel_kode.tambah_blok_aksi(aksi_1.dapatkan_nilai())
				aksi_2.dapatkan_aksi(0).geser_kebawah()
			else:
				aksi_2.tambahkan_aksi(aksi_1.dapatkan_nilai())
			aksi_1.hapus()
			if aksi_2.terlipat: aksi_2.lipat()
		else:
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
	elif node_induk is blok_kondisi:
		#print_debug("we are the kids from yesterday!")
		node_induk.node_fungsi.panel_kode.pilih_scope = node_induk.node_induk
		node_induk.node_fungsi.panel_kode.pilih_aksi = node_induk
		node_induk.node_fungsi.panel_kode.tambah_blok_aksi(aksi_1.dapatkan_nilai())
		aksi_1.hapus()
func pilih():
	#print_debug("@panel_kode::pilih_aksi = "+str(get_path()))
	if node_induk != null:
		if node_induk is blok_fungsi:
			node_induk.panel_kode.pilih_scope = node_induk
			node_induk.panel_kode.pilih_aksi = self
		else:
			node_induk.node_fungsi.panel_kode.pilih_scope = node_induk
			node_induk.node_fungsi.panel_kode.pilih_aksi = self
func hapus():
	if node_induk != null:
		if node_induk is blok_fungsi:
			node_induk.panel_kode.pilih_scope = node_induk
			node_induk.panel_kode.pilih_aksi = self
			node_induk.panel_kode.hapus_blok_aksi()
		else:
			node_induk.node_fungsi.panel_kode.pilih_scope = node_induk
			node_induk.node_fungsi.panel_kode.pilih_aksi = self
			node_induk.node_fungsi.panel_kode.hapus_blok_aksi()
	
