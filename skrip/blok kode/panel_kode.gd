extends Panel

signal jalankan_kode(kode : String)
signal tutup_panel()

var jalur_edit_aksi : NodePath
var fungsi_edit_aksi : Array[String]
var pilih_scope
var pilih_aksi
var daftar_kelas_sintaks : Array[Control]

func _tambah_skala(): $kontrol_skala/pengatur_skala.value += $kontrol_skala/pengatur_skala.step
func _kurang_skala(): $kontrol_skala/pengatur_skala.value -= $kontrol_skala/pengatur_skala.step
func _ketika_mengatur_skala(nilai):
	$kontrol_skala/nilai_skala.text = str(nilai)
	$wilayah_deklarasi/area_deklarasi.custom_minimum_size.x = 414 * nilai
	for blok_deklarasi in $wilayah_deklarasi/area_deklarasi.get_children():
		if blok_deklarasi is blok_fungsi:
			blok_deklarasi.atur_ukuran(nilai)
			for d_blok_aksi in blok_deklarasi.dapatkan_aksi():
				if d_blok_aksi.has_method("atur_ukuran"):
					d_blok_aksi.atur_ukuran(nilai)
	if pilih_aksi != null: pilih_aksi.grab_focus()

func buat_blok_kode(kode : String):
	var baris_kode = kode.split("\n")
	var fungsi : blok_fungsi
	var cabang : blok_kondisi
	var indentasi = 0
	for baris in baris_kode:
		# jika baris kode adalah deklarasi fungsi
		if baris.match("func *():"):
			var instance_fungsi : blok_fungsi = load("res://ui/blok kode/fungsi.tscn").instantiate()
			$wilayah_deklarasi/area_deklarasi.add_child(instance_fungsi)
			instance_fungsi.atur_nama(baris.split(" ")[1])
			instance_fungsi.panel_kode = self
			fungsi = instance_fungsi
			pilih_scope = fungsi
			indentasi = 0
		# jika baris adalah aksi fungsi
		elif baris.substr(0, 1) == "\t":
			# cek kondisi/percabangan atau loop mis. if, for, while
			if baris.substr(1).match("if *:"):
				cabang = load("res://ui/blok kode/kondisi/if.tscn").instantiate()
				fungsi.get_node("pemisah_vertikal_2/area_aksi").add_child(cabang)
				cabang.atur_nilai(baris.substr(1))
				cabang.node_fungsi = fungsi
				cabang.node_induk = fungsi
				# cek node sebelumya, kalau aksi, cek_urutan()!
				if fungsi.get_node("pemisah_vertikal_2/area_aksi").get_child(fungsi.get_node("pemisah_vertikal_2/area_aksi").get_child_count() - 2) is blok_aksi:
					fungsi.get_node("pemisah_vertikal_2/area_aksi").get_child(fungsi.get_node("pemisah_vertikal_2/area_aksi").get_child_count() - 2).cek_urutan()
				indentasi += 1
			elif cabang != null and baris.substr(indentasi, 1) == "\t":
				# cek sub-kondisi
				if baris.substr(indentasi + 1).match("if *:"):
					var tmp_cabang = load("res://ui/blok kode/kondisi/if.tscn").instantiate()
					cabang.get_node("pemisah_vertikal_2/area_aksi").add_child(tmp_cabang)
					tmp_cabang.atur_nilai(baris.substr(indentasi + 1))
					tmp_cabang.node_fungsi = fungsi
					tmp_cabang.node_induk = cabang
					tmp_cabang.cek_urutan()
					cabang = tmp_cabang
					indentasi += 1
				else:
					cabang.tambahkan_aksi(baris.substr(indentasi + 1))
			elif cabang != null and baris.substr(indentasi, 1) != "\t" and baris.substr(indentasi - 1, 1) == "\t" and cabang.node_induk is blok_kondisi:
				indentasi -= 1
				var tmp_cabang = cabang.node_induk
				cabang = tmp_cabang
				cabang.tambahkan_aksi(baris.substr(indentasi + 1))
			else:
				indentasi = 0
				cabang = null
				fungsi.tambahkan_aksi(baris.substr(indentasi + 1))
func hapus_blok_kode():
	for kode in $wilayah_deklarasi/area_deklarasi.get_children():
		kode.queue_free()
	# atur ulang nilai skala
	$kontrol_skala/nilai_skala.text = "1"
	$kontrol_skala/pengatur_skala.value = 1.0
	$wilayah_deklarasi/area_deklarasi.custom_minimum_size.x = 414
func tambah_blok_aksi(baris_kode : String):
	# kalau pilih_aksi belum di set tapi pilih_scope valid, tambah ke fungsi pertama
	if pilih_scope != null:
		# tambahkan aksi ke fungsi
		pilih_scope.tambahkan_aksi(baris_kode)
		# kalau pilih_aksi bukan di urutan terakhir, pindahin aksi yg ditambah ke bawah aksi yg dipilih
		if pilih_aksi != null:
			var urutan_aksi_dipilih = pilih_aksi.urutan
			var urutan_aksi_terakhir = -1
			var tambah_aksi
			# dapetin aksi terakhir, kalau pass, cek lagi -1 nya, kalau bukan pass terus ambil jadi tambah_aksi; ambil urutan jadi urutan_aksi_terakhir
			if !(pilih_aksi.get_parent().get_child(pilih_aksi.get_parent().get_child_count() - 1) is blok_pass):
				tambah_aksi = pilih_aksi.get_parent().get_child(pilih_aksi.get_parent().get_child_count() - 1)
				urutan_aksi_terakhir = tambah_aksi.urutan
			elif !(pilih_aksi.get_parent().get_child(pilih_aksi.get_parent().get_child_count() - 2) is blok_pass):
				tambah_aksi = pilih_aksi.get_parent().get_child(pilih_aksi.get_parent().get_child_count() - 2)
				urutan_aksi_terakhir = tambah_aksi.urutan
			# pindahin urutan tambah_aksi ke [urutan_aksi_dipilih + 1]
			tambah_aksi.get_parent().move_child(tambah_aksi, urutan_aksi_dipilih + 1)
			tambah_aksi.urutan = urutan_aksi_dipilih + 1
			tambah_aksi.cek_urutan()
			# pindahin urutan aksi[urutan_aksi_dipilih + 1] ke + 2; seterusnya sampai urutan_aksi_terakhir
			if pilih_aksi.get_parent().get_child(pilih_aksi.get_parent().get_child_count() - 1) is blok_pass\
			 and pilih_aksi.get_parent().get_child_count() > (urutan_aksi_dipilih + 2):
				for idx_cek_aksi in (urutan_aksi_terakhir - urutan_aksi_dipilih):
					var urutan_cek_aksi = urutan_aksi_dipilih + idx_cek_aksi + 2
					var cek_aksiaksi = pilih_aksi.get_parent().get_child(urutan_cek_aksi)
					if cek_aksiaksi.get("urutan") != null:
						cek_aksiaksi.urutan = urutan_cek_aksi
					if cek_aksiaksi.has_method("cek_urutan"):
						cek_aksiaksi.cek_urutan()
			elif pilih_aksi.get_parent().get_child_count() > (urutan_aksi_dipilih + 1):
				for idx_cek_aksi in (urutan_aksi_terakhir - urutan_aksi_dipilih):
					var urutan_cek_aksi = urutan_aksi_dipilih + idx_cek_aksi + 1
					var cek_aksiaksi = pilih_aksi.get_parent().get_child(urutan_cek_aksi)
					if cek_aksiaksi.get("urutan") != null:
						cek_aksiaksi.urutan = urutan_cek_aksi
					if cek_aksiaksi.has_method("cek_urutan"):
						cek_aksiaksi.cek_urutan()
			#print_debug(tambah_aksi.get_parent().get_children())
func hapus_blok_aksi():
	if pilih_scope != null and pilih_aksi != null:
		var urutan_aksi_dihapus = pilih_aksi.urutan
		var urutan_aksi_terakhir = -1
		var induk_aksi = pilih_aksi.get_parent()
		var tmp_pass
		if !(induk_aksi.get_child(induk_aksi.get_child_count() - 1) is blok_pass):
			urutan_aksi_terakhir = induk_aksi.get_child(induk_aksi.get_child_count() - 1).urutan
		elif !(induk_aksi.get_child(induk_aksi.get_child_count() - 2) is blok_pass):
			urutan_aksi_terakhir = induk_aksi.get_child(induk_aksi.get_child_count() - 2).urutan
			tmp_pass = induk_aksi.get_child(induk_aksi.get_child_count() - 1)
			induk_aksi.remove_child(tmp_pass)
		#print_debug("hapus aksi : " + str(urutan_aksi_dihapus) + " << " + str(pilih_aksi))
		induk_aksi.remove_child(pilih_aksi)
		pilih_aksi.queue_free()
		pilih_aksi = null
		#print_debug("aksi terakhir : " + str(urutan_aksi_terakhir) + " << " + str(induk_aksi.get_child(urutan_aksi_terakhir)))
		if urutan_aksi_dihapus == urutan_aksi_terakhir and urutan_aksi_dihapus > 0 and (urutan_aksi_dihapus - 1) < urutan_aksi_terakhir:
			var cek_aksiaksi = induk_aksi.get_child(urutan_aksi_dihapus - 1)
			#print_debug("cek : " + str(urutan_aksi_dihapus - 1) + " << " + cek_aksiaksi.name)
			if cek_aksiaksi.get("urutan") != null:
				cek_aksiaksi.urutan = urutan_aksi_dihapus - 1
			if cek_aksiaksi.has_method("cek_urutan"):
				cek_aksiaksi.cek_urutan()
		elif urutan_aksi_dihapus == 0 and urutan_aksi_dihapus == urutan_aksi_terakhir and tmp_pass == null:
			# jangan cek apapun, cukup tambahin pass
			# 08/06/24 :: jangan tambahin pass kalo udah ada!
			pilih_scope.tambahkan_aksi("pass")
		else:
			for idx_cek_aksi in (urutan_aksi_terakhir - urutan_aksi_dihapus):
				var urutan_cek_aksi = urutan_aksi_dihapus + idx_cek_aksi
				if (urutan_cek_aksi - 1) < induk_aksi.get_child_count():
					var cek_aksiaksi = induk_aksi.get_child(urutan_cek_aksi)
					#print_debug("cek : " + str(urutan_cek_aksi) + " << " + str(cek_aksiaksi))
					if cek_aksiaksi != null:
						if cek_aksiaksi.get("urutan") != null:
							cek_aksiaksi.urutan = urutan_cek_aksi
						if cek_aksiaksi.has_method("cek_urutan"):
							cek_aksiaksi.cek_urutan()
		if tmp_pass != null: induk_aksi.add_child(tmp_pass)
func buat_palet_sintaks(nama_grup : String, data : Dictionary):
	var label_aksi = Label.new()
	var label_pemisah = Label.new()
	label_aksi.text = nama_grup
	$palet_sintaks.add_child(label_aksi)
	for kelas_sintaks in data.keys():
		var node_kelas_sintaks = load("res://ui/blok kode/sintaks/kelas.scn").instantiate()
		$palet_sintaks.add_child(node_kelas_sintaks)
		node_kelas_sintaks.name = kelas_sintaks
		node_kelas_sintaks.text = kelas_sintaks + " >"
		if data[kelas_sintaks] is Array and data[kelas_sintaks].size() > 0:
			for aksi_sintaks in data[kelas_sintaks]:
				var nama_fungsi_aksi = aksi_sintaks[0]
				var kode_sintaks_aksi = aksi_sintaks[1]
				var jalur_ikon_aksi = aksi_sintaks[2]
				var node_aksi_sintaks : Button
				if nama_fungsi_aksi == "notifikasi(teks)":
					node_aksi_sintaks = load("res://ui/blok kode/sintaks/notifikasi.scn").instantiate()
				else:
					node_aksi_sintaks = load("res://ui/blok kode/sintaks/aksi.scn").instantiate()
				node_kelas_sintaks.daftar_aksi.add_child(node_aksi_sintaks)
				node_aksi_sintaks.text = nama_fungsi_aksi
				node_aksi_sintaks.kode = kode_sintaks_aksi
		daftar_kelas_sintaks.append(node_kelas_sintaks)
	$palet_sintaks.add_child(label_pemisah)
func hapus_palet_sintaks():
	for sintaks in $palet_sintaks.get_children():
		sintaks.queue_free()
	daftar_kelas_sintaks.clear()
func kompilasi_blok_kode():
	var hasil_kode = ""
	for b_deklarasi in $wilayah_deklarasi/area_deklarasi.get_children():
		if b_deklarasi is blok_fungsi:
			hasil_kode += "func " + b_deklarasi.dapatkan_nama() + "\n"
			if b_deklarasi.dapatkan_aksi().size() > 0:
				for b_aksi in b_deklarasi.dapatkan_aksi():
					if b_aksi is blok_aksi:
						hasil_kode += "\t" + b_aksi.dapatkan_nilai() + "\n"
					elif b_aksi is blok_kondisi:
						# dapetin nilai kondisi / nama kondisi
						hasil_kode += "\t" + b_aksi.dapatkan_nilai() + "\n"
						# dapetin aksi dari kondisi / sub-kondisi
						for bb_aksi in b_aksi.dapatkan_nilai_aksi():
							hasil_kode += "\t" + bb_aksi + "\n"
					elif b_aksi is Label:
						hasil_kode += "\t" + b_aksi.text + "\n"
			else: hasil_kode += "\tpass\n"
	emit_signal("jalankan_kode", hasil_kode)

func ubah_nilai_aksi(jalur_aksi : NodePath, fungsi : Array[String], nilai_parameter : Array):
	for prm in $panel_edit/Panel/ScrollContainer/VBoxContainer.get_children():
		prm.queue_free()
	var node_parameter : HBoxContainer
	var urutan_parameter = 1
	jalur_edit_aksi = jalur_aksi
	fungsi_edit_aksi = fungsi.duplicate()
	for data_parameter in nilai_parameter:
		#print_debug(str(data_parameter) + " << " + type_string(typeof(data_parameter)))
		if typeof(data_parameter) == TYPE_INT:
			node_parameter = load("res://ui/blok kode/parameter/int.tscn").instantiate()
			$panel_edit/Panel/ScrollContainer/VBoxContainer.add_child(node_parameter)
			node_parameter.get_node("nama_parameter").set("text", "x"+str(urutan_parameter))
			node_parameter.get_node("nilai_parameter").set("value", data_parameter)
		elif typeof(data_parameter) == TYPE_STRING:
			node_parameter = load("res://ui/blok kode/parameter/string.tscn").instantiate()
			$panel_edit/Panel/ScrollContainer/VBoxContainer.add_child(node_parameter)
			node_parameter.get_node("nama_parameter").set("text", "x"+str(urutan_parameter))
			node_parameter.get_node("nilai_parameter").set("text", data_parameter)
		elif typeof(data_parameter) == TYPE_COLOR:
			node_parameter = load("res://ui/blok kode/parameter/color.tscn").instantiate()
			$panel_edit/Panel/ScrollContainer/VBoxContainer.add_child(node_parameter)
			node_parameter.get_node("nama_parameter").set("text", "x"+str(urutan_parameter))
			node_parameter.get_node("nilai_parameter").set("color", data_parameter)
		elif typeof(data_parameter) == TYPE_ARRAY:
			node_parameter = load("res://ui/blok kode/parameter/array.tscn").instantiate()
			$panel_edit/Panel/ScrollContainer/VBoxContainer.add_child(node_parameter)
			node_parameter.get_node("nama_parameter").set("text", "x"+str(urutan_parameter))
			node_parameter.get_node("nilai_parameter").set("text", str(data_parameter))
		elif typeof(data_parameter) == TYPE_VECTOR2:
			node_parameter = load("res://ui/blok kode/parameter/vector2.tscn").instantiate()
			$panel_edit/Panel/ScrollContainer/VBoxContainer.add_child(node_parameter)
			node_parameter.get_node("nama_parameter").set("text", "x"+str(urutan_parameter))
			node_parameter.get_node("data_parameter/data_1/nilai_x").set("value", str(data_parameter.x))
			node_parameter.get_node("data_parameter/data_2/nilai_y").set("value", str(data_parameter.y))
		elif typeof(data_parameter) == TYPE_VECTOR3:
			node_parameter = load("res://ui/blok kode/parameter/vector3.tscn").instantiate()
			$panel_edit/Panel/ScrollContainer/VBoxContainer.add_child(node_parameter)
			node_parameter.get_node("nama_parameter").set("text", "x"+str(urutan_parameter))
			node_parameter.get_node("data_parameter/data_1/nilai_x").set("value", str(data_parameter.x))
			node_parameter.get_node("data_parameter/data_2/nilai_y").set("value", str(data_parameter.y))
			node_parameter.get_node("data_parameter/data_3/nilai_z").set("value", str(data_parameter.z))
		elif typeof(data_parameter) == TYPE_BOOL:
			node_parameter = load("res://ui/blok kode/parameter/bool.tscn").instantiate()
			$panel_edit/Panel/ScrollContainer/VBoxContainer.add_child(node_parameter)
			node_parameter.get_node("nama_parameter").set("text", "x"+str(urutan_parameter))
			node_parameter.get_node("nilai_parameter").set("button_pressed", data_parameter)
		urutan_parameter += 1
	$animasi.play("tampilkan_panel_edit")
func terapkan_nilai_aksi():
	$panel_edit/Panel/batal.disabled = true
	$panel_edit/Panel/oke.disabled = true
	if get_node_or_null(jalur_edit_aksi) != null and get_node(jalur_edit_aksi) is blok_aksi:
		var hasil_aksi = ""
		var hasil_parameter = ""
		for aksi in $panel_edit/Panel/ScrollContainer/VBoxContainer.get_children():
			if hasil_parameter.length() > 0: hasil_parameter += ", "
			if aksi.get_node_or_null("nilai_parameter") != null:
				if aksi.get_node("nilai_parameter") is SpinBox:				# int
					hasil_parameter += str(aksi.get_node("nilai_parameter").value)
				elif aksi.get_node("nilai_parameter") is TextEdit:			# string
					var nilai_string : String = aksi.get_node("nilai_parameter").text
					hasil_parameter += "\"" + nilai_string.replace('\n', "\\n") + "\""
				elif aksi.get_node("nilai_parameter") is ColorPickerButton:	# color
					hasil_parameter += "Color(\"#" + aksi.get_node("nilai_parameter").color.to_html() + "\")"
				elif aksi.get_node("nilai_parameter") is LineEdit:			# array
					hasil_parameter += aksi.get_node("nilai_parameter").text
				elif aksi.get_node("nilai_parameter") is CheckButton:		# bool
					hasil_parameter += str(aksi.get_node("nilai_parameter").button_pressed)
			elif aksi.get_node_or_null("tipe_parameter") != null and aksi.get_node_or_null("data_parameter") != null:
				if aksi.get_node("tipe_parameter").text == "Vector2":
					hasil_parameter += "Vector2(%s, %s)" % [str(aksi.get_node("data_parameter/data_1/nilai_x").value), str(aksi.get_node("data_parameter/data_2/nilai_y").value)]
				elif aksi.get_node("tipe_parameter").text == "Vector3":
					hasil_parameter += "Vector3(%s, %s, %s)" % [str(aksi.get_node("data_parameter/data_1/nilai_x").value), str(aksi.get_node("data_parameter/data_2/nilai_y").value), str(aksi.get_node("data_parameter/data_3/nilai_z").value)]
		hasil_aksi = fungsi_edit_aksi[0] + hasil_parameter + fungsi_edit_aksi[1]
		await get_node(jalur_edit_aksi).atur_nilai(hasil_aksi)
	$animasi.play_backwards("tampilkan_panel_edit")
	await $animasi.animation_finished
	$panel_edit/Panel/batal.disabled = false
	$panel_edit/Panel/oke.disabled = false
func batal_ubah_nilai_aksi():
	jalur_edit_aksi = NodePath()
	fungsi_edit_aksi.clear()
	$animasi.play_backwards("tampilkan_panel_edit")

func _perluas_tampilan(): $animasi.play("perluas")
func _perkecil_tampilan(): $animasi.play("perkecil")

func _ketika_menutup_panel():
	kompilasi_blok_kode()
	emit_signal("tutup_panel")

func _uji_tambah_aksi():
	tambah_blok_aksi("Panku.notify(\"teks\")")
