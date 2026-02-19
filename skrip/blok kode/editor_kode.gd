extends Control
class_name EditorBlokKode

@onready var daftar_blok_kode = $HSplitContainer/Panel
@onready var area_blok_kode = $HSplitContainer/ScrollContainer/VBoxContainer

static var daftar_kode : Array[String]

static func tambah_kode(kode : String) -> int:
	daftar_kode.append(kode)
	return daftar_kode.size()
static func dapatkan_daftar_kode() -> Array:
	return daftar_kode
static func hapus_kode(baris : int) -> void:
	daftar_kode.remove_at(baris)

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
			tmp_kode += "\n" + tmp_baris_kode
	return tmp_kode

func _parse_baris_instruksi(instruksi: String, indent_level: int):
	# ==== REGEX DASAR ====
	var regex_extends = RegEx.new()
	regex_extends.compile("^extends\\s+(\\w+)")

	var regex_func = RegEx.new()
	regex_func.compile("^func\\s+(\\w+)\\((.*?)\\):")

	var regex_instruction = RegEx.new()
	regex_instruction.compile("^s+(.*)")

	var regex_method_call = RegEx.new()
	regex_method_call.compile("^(\\w+)\\.(\\w+)\\((.*)\\)")

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
	var regex_var_assign = RegEx.new()
	regex_var_assign.compile("^var\\s+(\\w+)\\s*=\\s*(.*)")

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
		print("Blok ELIF (Indent:", indent_level, ")")
		var kondisi = _parse_kondisi(cocok.get_string(1))
		print(kondisi)
		return

	# -----------------
	# ELSE
	# -----------------
	cocok = regex_else.search(instruksi)
	if cocok:
		print("Blok ELSE (Indent:", indent_level, ")")
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
	cocok = regex_var_assign.search(instruksi)
	if cocok:
		print("Blok VAR ASSIGN:",
			  cocok.get_string(1),
			  "=",
			  cocok.get_string(2))
		return

	# -----------------
	# ASSIGN
	# -----------------
	cocok = regex_assign.search(instruksi)
	if cocok:
		print("Blok ASSIGN:",
			  cocok.get_string(1),
			  "=",
			  cocok.get_string(2))
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
			  "Arg:",
			  cocok.get_string(3),
			  "Indent:", indent_level)
		_buat_blok("Instruksi", indent_level, instruksi, {
			"objek": cocok.get_string(1),
			"metode": cocok.get_string(2),
			"argumen": cocok.get_string(3)
		})
		return

	# -----------------
	# PRINT
	# -----------------
	cocok = regex_instruction.search(instruksi)
	if cocok:
		print("Blok PRINT:", cocok.get_string(1),
			  "Indent:", indent_level)
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
		"IF":
			print("Blok IF (Indent:", indentasi, ")")
			node_blok_kode.buat_blok_if(data)
	node_blok_kode._setup()

func _parse_kondisi(kondisi: String) -> Dictionary:
	var parser = ConditionParser.new()
	return parser.parse(kondisi)

func _ready() -> void:
	konversi_kode_menjadi_blok("extends Node\nfunc _mulai():\n\tif ((0 > 1) or (1 > 3)):\n\t\tPanku.notify(\"ProgrammerIndonesia44\")\n\t\tif (true):\n\t\t\tPanku.notify(\"test2\")\nfunc _proses():\n\tPanku.notify(\"test\")")
	print_debug(dapatkan_daftar_kode())
func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("daftar_pemain"):
		$HSplitContainer/CodeEdit.text = konversi_blok_menjadi_kode()
