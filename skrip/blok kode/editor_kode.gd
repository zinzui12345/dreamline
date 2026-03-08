extends Control
class_name EditorBlokKode

@onready var daftar_blok_kode : DaftarBlokKode = $HSplitContainer/Pallete
@onready var area_blok_kode : AreaBlokKode = $HSplitContainer/ScrollContainer/VBoxContainer

static var daftar_kode : Dictionary = {}
static var daftar_variabel : Dictionary = {}
static var _id_kosong : Array[int] = []
static var _id_selanjutnya : int = 1
static var _id_variabel_kosong : Array[int] = []
static var _id_variabel_selanjutnya : int = 1

static func tambah_kode(node : Control) -> int:
	var id : int
	if _id_kosong.size() > 0:
		id = _id_kosong.pop_front()
	else:
		id = _id_selanjutnya
		_id_selanjutnya += 1
	daftar_kode.set(id, node)
	return id
static func dapatkan_daftar_kode() -> Dictionary:
	return daftar_kode
static func hapus_kode(id : int) -> void:
	if daftar_kode.has(id):
		daftar_kode.erase(id)
		_id_kosong.append(id)
		_id_kosong.sort()

static func tambah_variabel(nama : String, tipe : String) -> int:
	var id_variabel : int
	if _id_variabel_kosong.size() > 0:
		id_variabel = _id_variabel_kosong.pop_front()
	else:
		id_variabel = _id_variabel_selanjutnya
		_id_variabel_selanjutnya += 1
	daftar_variabel[id_variabel] = {
		"nama": nama,
		"tipe": tipe,
		"deklarasi": []
	}
	return id_variabel
static func dapatkan_variabel(nama_variabel : String) -> Dictionary:
	for id_variabel in daftar_variabel:
		if daftar_variabel[id_variabel]["nama"] == nama_variabel:
			return {
				"id":	id_variabel,
				"tipe":	daftar_variabel[id_variabel]["tipe"]
			}
	return {}
static func dapatkan_daftar_variabel() -> Dictionary:
	return daftar_variabel
static func dapatkan_daftar_variabel_berdasarkan_tipe(tipe : String) -> Dictionary:
	var hasil : Dictionary = {}
	if tipe == "" or tipe == "Variant":
		return daftar_variabel
	for id_variabel in daftar_variabel:
		if daftar_variabel[id_variabel]["tipe"] == tipe:
			hasil[id_variabel] = daftar_variabel[id_variabel]
	return hasil
static func cek_apakah_variabel_sudah_ada(nama_variabel : String) -> bool:
	for id_variabel in daftar_variabel:
		if daftar_variabel[id_variabel]["nama"] == nama_variabel:
			return true
	return false
static func ubah_nama_variabel(id_variabel : int, nama_baru : String) -> void:
	if not daftar_variabel.has(id_variabel):
		return
	
	# Cegah nama variabel duplikat
	if cek_apakah_variabel_sudah_ada(nama_baru):
		return
	
	var data_variabel = daftar_variabel[id_variabel]
	var nama_lama = data_variabel["nama"]
	
	# Ubah nama pada data variabel
	data_variabel["nama"] = nama_baru
	
	# ======================================================
	# UPDATE SEMUA BLOK YANG MENGGUNAKAN VARIABEL INI
	# ======================================================
	# Setiap node di "deklarasi" diasumsikan adalah blok yang
	# menampilkan nama variabel (misalnya label atau input)
	for blok in data_variabel["deklarasi"]:
		#blok adalah ParameterInput
		if blok and blok.has_method("_ubah_nama_variabel"):
			blok._ubah_nama_variabel(nama_lama, nama_baru)
static func ubah_tipe_variabel(id_variabel : int, tipe_baru : String) -> void:
	if not daftar_variabel.has(id_variabel):
		return
	
	var data_variabel = daftar_variabel[id_variabel]
	data_variabel["tipe"] = tipe_baru
	
	# ======================================================
	# UPDATE BLOK YANG BERGANTUNG PADA TIPE
	# ======================================================
	# Misalnya blok operator atau input yang harus berubah tipe
	#for blok in data_variabel["deklarasi"]:
		# blok adalah ParameterInput
		#if blok and blok.has_method("update_tipe_variabel"):
			#blok.update_tipe_variabel(tipe_baru)
static func daftar_penggunaan_variabel(id_variabel:int, blok:Node) -> void:
	if not daftar_variabel.has(id_variabel):
		return
	daftar_variabel[id_variabel]["deklarasi"].append(blok)
static func hapus_penggunaan_variabel(id_variabel:int, blok:Node) -> void:
	if not daftar_variabel.has(id_variabel):
		return
	daftar_variabel[id_variabel]["deklarasi"].erase(blok)
static func hapus_variabel(id : int) -> void:
	if daftar_variabel.has(id):
		# ======================================================
		# UPDATE SEMUA BLOK YANG MENGGUNAKAN VARIABEL APAPUN
		# ======================================================
		# TODO : implementasi
		daftar_variabel.erase(id)
		_id_variabel_kosong.append(id)
		_id_variabel_kosong.sort()

const warna_blok_fungsi : Color = Color("073984ff")
const warna_blok_variabel : Color = Color("11694fff")
const warna_blok_logika : Color = Color("5b2d07ff")
const warna_blok_instruksi : Color = Color("5f5fd3ff")
const warna_blok_pernyataan : Color = Color("4f1319ff")

func konversi_kode_menjadi_blok(kode : String) -> void:
	var baris_kode : Array = kode.split("\n")

	for instruksi in baris_kode:
		var raw_indent = instruksi.length() - instruksi.strip_edges(true, false).length()
		var indent_level = raw_indent # atau /4 kalau pakai 4 spasi

		instruksi = instruksi.strip_edges()
		if instruksi.is_empty():
			continue

		var blok = _parse_baris_instruksi(instruksi, indent_level)
		if blok == null:
			continue
func konversi_blok_menjadi_kode() -> String:
	var tmp_kode : String = ""
	for blok_kode in area_blok_kode.get_children():
		if blok_kode is BlokKode:
			var baris_kode : String = blok_kode.hasilkan_kode()
			var tmp_baris_kode : String = ""
			var pisah_baris_kode : Array = baris_kode.split("\n")
			for instruksi in pisah_baris_kode:
				tmp_baris_kode += "\n"
				for jumlah_indentasi in blok_kode.indent_level:
					tmp_baris_kode += "\t"
				tmp_baris_kode += instruksi
			if blok_kode.block_type in ["Fungsi", "Extends"]:
				tmp_kode += "\n"
			tmp_kode += tmp_baris_kode
	if tmp_kode.begins_with("\n\n"):
		tmp_kode = tmp_kode.substr(2)
	return tmp_kode

func _notification(notification_type):
	match notification_type:
		NOTIFICATION_DRAG_BEGIN:
			area_blok_kode.mouse_filter = Control.MOUSE_FILTER_STOP
		NOTIFICATION_DRAG_END:
			area_blok_kode.mouse_filter = Control.MOUSE_FILTER_PASS

func _parse_baris_instruksi(instruksi: String, indent_level: int):
	# ==== REGEX DASAR ====
	var regex_extends = RegEx.new()
	regex_extends.compile("^extends\\s+(\\w+)")

	var regex_func = RegEx.new()
	regex_func.compile("^func\\s+(\\w+)\\((.*?)\\):")

	var regex_method_call = RegEx.new()
	regex_method_call.compile("^(\\w+)\\.(\\w+)\\((.*)\\)")
	
	var regex_instruction = RegEx.new()
	regex_instruction.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*\((.*)\)$")

	# ==== STRUKTUR KONTROL ====
	var regex_if = RegEx.new()
	regex_if.compile("^if\\s+(.*):")

	var regex_elif = RegEx.new()
	regex_elif.compile("^elif\\s+(.*):")

	var regex_else = RegEx.new()
	regex_else.compile("^else:")

	var regex_for = RegEx.new()
	regex_for.compile("^for\\s+(\\w+)\\s+in\\s+(.*):")

	var regex_while = RegEx.new()
	regex_while.compile("^while\\s+(.*):")

	# ==== ASSIGNMENT ====
	var regex_var = RegEx.new()
	regex_var.compile("^var\\s+(\\w+)(?:\\s*:\\s*([\\w\\[\\],\\s]+))?(?:\\s*=\\s*(.*))?$")

	var regex_assign = RegEx.new()
	regex_assign.compile("^(\\w+)\\s*=\\s*(.*)")

	# ==== OPERATOR PERBANDINGAN ====
	var regex_comparison = RegEx.new()
	regex_comparison.compile("(.+)\\s*(==|!=|>=|<=|>|<)\\s*(.+)")

	var cocok

	# -----------------
	# EXTENDS
	# -----------------
	cocok = regex_extends.search(instruksi)
	if cocok:
		_buat_blok("Extends", indent_level, instruksi, { "node_induk": cocok.get_string(1) })
		return
	
	# -----------------
	# FUNCTION
	# -----------------
	cocok = regex_func.search(instruksi)
	if cocok:
		_buat_blok("Fungsi", indent_level, instruksi, {
			"nama": cocok.get_string(1),
			"parameter": cocok.get_string(2)
		})
		return
	
	# -----------------
	# IF
	# -----------------
	cocok = regex_if.search(instruksi)
	if cocok:
		var kondisi = _parse_kondisi(cocok.get_string(1))
		_buat_blok("IF", indent_level, instruksi, kondisi)
		return

	# -----------------
	# ELIF
	# -----------------
	cocok = regex_elif.search(instruksi)
	if cocok:
		var kondisi = _parse_kondisi(cocok.get_string(1))
		_buat_blok("ELIF", indent_level, instruksi, kondisi)
		return

	# -----------------
	# ELSE
	# -----------------
	cocok = regex_else.search(instruksi)
	if cocok:
		_buat_blok("ELSE", indent_level, instruksi, {})
		return

	# -----------------
	# FOR
	# -----------------
	cocok = regex_for.search(instruksi)
	if cocok:
		print("Blok FOR:", cocok.get_string(1), 
			  "in", cocok.get_string(2),
			  "Indent:", indent_level)
		return

	# -----------------
	# WHILE
	# -----------------
	cocok = regex_while.search(instruksi)
	if cocok:
		_parse_kondisi(cocok.get_string(1))
		print("Blok WHILE (Indent:", indent_level, ")")
		return

	# -----------------
	# VAR ASSIGN
	# -----------------
	cocok = regex_var.search(instruksi)
	if cocok:
		_buat_blok("Variabel", indent_level, instruksi, {
			"nama": cocok.get_string(1),
			"tipe": cocok.get_string(2),
			"nilai": cocok.get_string(3)
		})
		return

	# -----------------
	# ASSIGN
	# -----------------
	cocok = regex_assign.search(instruksi)
	if cocok:
		_buat_blok("ASSIGN", indent_level, instruksi, {
			"nama": cocok.get_string(1),
			"kalkulasi": "",
			"nilai": cocok.get_string(2)
		})
		return

	# -----------------
	# METHOD CALL
	# -----------------
	cocok = regex_method_call.search(instruksi)
	if cocok:
		print("Blok METHOD CALL:",
			  cocok.get_string(1),
			  ".",
			  cocok.get_string(2),
			  " Arg:",
			  cocok.get_string(3),
			  " Indent:", indent_level)
		_buat_blok("Instruksi", indent_level, instruksi, {
			"objek": cocok.get_string(1),
			"metode": cocok.get_string(2),
			"argumen": cocok.get_string(3)
		})
		return
	
	# =========================
	# DIRECT METHOD CALL
	# =========================
	cocok = regex_instruction.search(instruksi)
	if cocok:
		var method_name = cocok.get_string(1)
		var arg = cocok.get_string(2)
		print("Blok DIRECT CALL:", method_name, " Arg:", arg)
		_buat_blok("Instruksi", indent_level, instruksi, {
			"objek": "",
			"metode": method_name,
			"argumen": arg
		})
		return

	print("Instruksi tidak dikenali:", instruksi)

	return null

func _buat_blok(tipe: String, indentasi: int, _instruksi: String, data : Dictionary) -> void:
	var node_blok_kode : BlokKode = load("res://ui/blok kode/blok_kode.scn").instantiate()
	node_blok_kode.indent_level = indentasi
	area_blok_kode.add_child(node_blok_kode)
	match tipe:
		"Extends":
			print("Blok EXTENDS:", data.node_induk)
			node_blok_kode.buat_blok_extends(data.node_induk)
		"Fungsi":
			print("Blok FUNGSI:", data.nama, " Parameter:", data.parameter)
			node_blok_kode.buat_blok_fungsi(data.nama, data.parameter)
		"Instruksi":
			print("Blok METHOD CALL:", data.metode)
			node_blok_kode.buat_blok_instruksi(data.objek, data.metode, data.argumen)
		"Variabel":
			print("Blok VAR ASSIGN:", data.nama)
			print("     VAR TYPE:", data.tipe)
			print("     VAR VALUE:", data.nilai)
			node_blok_kode.buat_blok_variabel(data.nama, data.tipe, data.nilai)
		"ASSIGN":
			print("Blok ASSIGN:", data.nama, " << ", data.nilai)
			node_blok_kode.buat_blok_penetapan_nilai_variabel(data.nama, data.nilai, data.kalkulasi)
		"IF":
			print("Blok IF (Indent:", indentasi, ")")
			node_blok_kode.buat_blok_if(data)
		"ELIF":
			print("Blok ELIF (Indent:", indentasi, ")")
			node_blok_kode.buat_blok_elif(data)
		"ELSE":
			print("Blok ELSE (Indent:", indentasi, ")")
			node_blok_kode.buat_blok_else()
	node_blok_kode._setup()

func _parse_kondisi(kondisi: String) -> Dictionary:
	var parser = ConditionParser.new()
	return parser.parse(kondisi)

func _ready() -> void:
	var test_pallete : BlokKode = load("res://ui/blok kode/blok_kode.scn").instantiate()
	test_pallete.name = "fungsi setup"
	$HSplitContainer/Pallete.add_child(test_pallete)
	test_pallete.buat_blok_fungsi("_setup", "")
	hapus_kode(test_pallete.block_id - 1)
	test_pallete.block_id = -1
	konversi_kode_menjadi_blok($kode_debug.text)
	$kode_debug.hide()
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("daftar_pemain"):
		$HSplitContainer/CodeEdit.text = konversi_blok_menjadi_kode()
	
	if Input.is_action_just_pressed("mode_bermain"):
		print("daftar saat ini :")
		print(dapatkan_daftar_variabel())
