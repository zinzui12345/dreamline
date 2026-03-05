extends PanelContainer
class_name BlokKode

# Tipe blok: COMMAND, IF, WHILE
@export_enum("Fungsi", "Variabel", "Pernyataan", "Logika", "Instruksi") var block_type = "Fungsi"
@export var use_once : bool = false
@export var locked : bool = false
@export var code : String = ""
@export var indent_level : int = 0
@export var inherit_class : String = ""
@onready var header_container = $VBoxContainer/MarginHeader/Header
@onready var body_container = $VBoxContainer/MarginBody/HBoxContainer/Body

# Instruksi
@export var instruction_object : String = ""
@export var instruction_method : String = ""
@export var instruction_argument : Array[Node]

# Logika
@export_enum("if", "elif", "else") var logic_type = "if"
@export var logic_input : Node
@export var logic_elif_blocks : VBoxContainer
@export var logic_else_block : VBoxContainer

# Variabel
@export var variable_name : LineEdit
@export var set_variable_name : ParameterInput
@export var variable_type : OptionButton
@export var variable_value : ParameterInput
@export var calc_variable_value_by : String # TODO : implementasi

const EditorKode = preload("res://skrip/blok kode/editor_kode.gd")

var block_id : int = -1

func _setup():
	# Sembunyikan body jika bukan IF atau WHILE
	if block_type not in ["Fungsi", "Logika"]:
		body_container.hide()
		$VBoxContainer/MarginBody.hide()
	# Sesuaikan indentasi berdasarkan blok di atasnya
	var parent = get_parent()
	var sibling_atas = parent.get_child(get_index() - 1) if get_index() > 0 else null
	if sibling_atas != null:
		if indent_level > sibling_atas.indent_level: # FIXME : kalau parent-nya elif/else, malah masuk ke blok if!
			parent.remove_child(self)
			if sibling_atas.logic_type == "if":
				if sibling_atas.logic_else_block != null and sibling_atas.logic_else_block.get_child_count() > 0:
					sibling_atas.logic_else_block.get_child(0).body_container.add_child(self)
				elif sibling_atas.logic_elif_blocks != null and sibling_atas.logic_elif_blocks.get_child_count() > 0:
					sibling_atas.logic_elif_blocks.get_child(sibling_atas.logic_elif_blocks.get_child_count() - 1).body_container.add_child(self)
				else:
					sibling_atas.body_container.add_child(self)
			else:
				sibling_atas.body_container.add_child(self)
			if (indent_level - sibling_atas.indent_level) > 1:
				_setup()
		if logic_type == "elif":
			if block_type == "Logika" and sibling_atas.block_type == "Logika" and sibling_atas.logic_type == "if" and self.get_parent() == parent:
				parent.remove_child(self)
				sibling_atas.logic_elif_blocks.add_child(self)
			else:
				_setup()
		if logic_type == "else":
			if block_type == "Logika" and sibling_atas.block_type == "Logika" and sibling_atas.logic_type == "if" and sibling_atas.logic_else_block.get_child_count() == 0:
				parent.remove_child(self)
				sibling_atas.logic_else_block.add_child(self)
			else:
				_setup()
	sesuaikan_indentasi()

# 1. Mulai Dragging
func _get_drag_data(_at_position):
	if locked: return null
	
	#var preview = Label.new()
	#preview.text = block_type
	#set_drag_preview(preview)
	var preview = self.duplicate()
	set_drag_preview(preview)
	self.visible = false
	
	# Kita return "self" (node ini) sebagai data yang dibawa
	if get_parent() is DaftarBlokKode:
		return self.duplicate()
	else:
		return self

# 2. Jika Drag selesai
func _notification(notification_type):
	match notification_type:
		NOTIFICATION_DRAG_END:
			self.visible = true
			sesuaikan_indentasi()

# 3. Cek apakah bisa didrop di sini
func _can_drop_data(_at_position, data):
	if locked: return false
	if data is BlokKode and data != self:
		if data.use_once and data.code in EditorKode.dapatkan_daftar_kode():
			return false
		if data.get_parent() is AreaBlokKode:
			if data.block_type == "Fungsi" and block_type != "Fungsi":
				return true
		if data.block_type == "Instruksi" and block_type != "Variabel":
			return true
		elif data.block_type == "Logika" and block_type != "Variabel" and data.logic_type not in ["elif", "else"]:
			return true
		elif data.block_type == "Logika" and block_type == "Logika" and logic_type == "if" and data.logic_type == "elif":
			return true
		elif data.block_type == "Logika" and block_type == "Logika" and logic_type == "if" and data.logic_type == "else" and logic_else_block.get_child_count() == 0:
			return true
		#elif get_parent() is AreaBlokKode and data.block_type in ["Fungsi", "Pernyataan"]:
			#return true
	return false

# 4. Saat dilepas (Drop)
func _drop_data(_at_position, data):
	# Pindahkan blok yang didrag menjadi anak dari blok ini
	# Logika: Jika didrop di blok IF/WHILE, masuk ke body. 
	# Jika didrop di blok biasa, taruh di bawahnya (sebagai sibling).
	
	var new_parent = self
	
	if block_type in ["Fungsi", "Logika"]:
		if data.logic_type == "elif" and logic_type == "if" and logic_elif_blocks != null:
			new_parent = logic_elif_blocks
		elif data.logic_type == "else" and logic_type == "if" and logic_else_block != null:
			new_parent = logic_else_block
		else:
			# Masukkan ke dalam container body (Nested)
			new_parent = body_container
	else:
		# Masukkan ke parent dari blok ini (Sibling/Tetangga)
		new_parent = get_parent()
	
	# Hapus dari parent lama
	data.get_parent().remove_child(data)
	# Tambah ke parent baru
	new_parent.add_child(data)
	sesuaikan_indentasi()
	
	# Opsional: Atur urutan sibling jika perlu
	if new_parent != body_container:
		new_parent.move_child(data, get_index() + 1)

func sesuaikan_indentasi() -> void:
	var induk = _dapatkan_induk()
	if induk is AreaBlokKode:
		indent_level = 0
	elif induk is BlokKode:
		if induk.block_type == "Logika" and induk.logic_type == "if" and logic_type in ["elif", "else"]:
			indent_level = induk.indent_level
		else:
			indent_level = induk.indent_level + 1
	if body_container.get_child_count() > 0:
		for sub_code in body_container.get_children():
			if sub_code is BlokKode:
				sub_code.sesuaikan_indentasi()
	if logic_elif_blocks != null and logic_elif_blocks.get_child_count() > 0:
		for sub_code in logic_elif_blocks.get_children():
			if sub_code is BlokKode:
				sub_code.sesuaikan_indentasi()
	if logic_else_block != null and logic_else_block.get_child_count() > 0:
		if logic_else_block.get_child(0) is BlokKode:
			logic_else_block.get_child(0).sesuaikan_indentasi()
func sesuaikan_warna(warna : Color) -> void:
	set("theme_override_styles/panel", get("theme_override_styles/panel").duplicate())
	get("theme_override_styles/panel").set("bg_color", warna)
	#get("theme_override_styles/panel").set("border_color", warna)

func buat_blok_extends(nama_kelas : String) -> void:
	var label_tampilan = Label.new()
	var instruksi = "extends " + nama_kelas + "\n"
	label_tampilan.text = "Mewarisi " + nama_kelas
	code = instruksi
	locked = true
	use_once = true
	block_type = "Pewarisan"
	block_id = EditorKode.tambah_kode(self)
	header_container.add_child(label_tampilan)
	sesuaikan_warna(EditorKode.warna_blok_pernyataan)
func buat_blok_fungsi(nama_fungsi : String, parameter : String) -> void:
	var label_tampilan = Label.new()
	var instruksi = "func " + nama_fungsi + "(" + parameter + "):"
	label_tampilan.text = "Ketika " + nama_fungsi
	code = instruksi
	use_once = true
	block_id = EditorKode.tambah_kode(self)
	header_container.add_child(label_tampilan)
	sesuaikan_warna(EditorKode.warna_blok_fungsi)
func buat_blok_instruksi(target_objek : String, metode : String, argumen : String) -> void:
	var label_tampilan = Label.new()
	var daftar_argumen : Array = _parse_argumen(argumen)
	label_tampilan.text = "Panggil " + metode + (" pada " + target_objek if target_objek.length() > 0 else "") + " dengan "
	header_container.add_child(label_tampilan)
	instruction_argument = []
	for data_argumen in daftar_argumen:
		print("Argumen hasil parsing:", data_argumen)
		var input_argumen : ParameterInput = load("res://ui/blok kode/parameter_input.tscn").instantiate()
		var _condition_parser := ConditionParser.new()
		var parameter_data : Dictionary = _condition_parser.parse(data_argumen)
		input_argumen.tentukan_parameter(parameter_data)
		input_argumen.name = "argumen_" + str(header_container.get_child_count())
		input_argumen.attached = true
		header_container.add_child(input_argumen)
		instruction_argument.append(input_argumen)
		input_argumen._setup()
	instruction_object = target_objek
	instruction_method = metode
	block_type = "Instruksi"
	var instruksi = hasilkan_kode()
	code = instruksi
	block_id = EditorKode.tambah_kode(self)
	sesuaikan_warna(EditorKode.warna_blok_instruksi)
func buat_blok_variabel(nama : String, tipe : String, nilai : String) -> void:
	var label_tampilan_1 = Label.new()
	var label_tampilan_2 = Label.new()
	var label_tampilan_3 = Label.new()
	variable_name = load("res://ui/blok kode/buat_nama_variabel.tscn").instantiate()
	label_tampilan_1.text = "Definisikan Variabel "
	header_container.add_child(label_tampilan_1)
	header_container.add_child(variable_name)
	variable_name.text = nama
	block_type = "Variabel"
	if tipe.length() > 0:
		variable_type = load("res://ui/blok kode/buat_tipe_variabel.tscn").instantiate()
		label_tampilan_2.text = " dengan tipe "
		header_container.add_child(label_tampilan_2)
		header_container.add_child(variable_type)
		variable_type.atur_tipe(tipe.replace(' ', ''))
	if nilai.length() > 0:
		variable_value = load("res://ui/blok kode/parameter_input.tscn").instantiate()
		label_tampilan_3.text = " dengan nilai "
		header_container.add_child(label_tampilan_3)
		header_container.add_child(variable_value)
		variable_value.attached = true
		var _condition_parser := ConditionParser.new()
		var parameter_data : Dictionary = _condition_parser.parse(nilai)
		variable_value.tentukan_parameter(parameter_data)
		variable_value._setup()
	var sintaks = hasilkan_kode()
	code = sintaks
	block_id = EditorKode.tambah_kode(self)
	sesuaikan_warna(EditorKode.warna_blok_variabel)
func buat_blok_penetapan_nilai_variabel(nama : String, nilai : String, kalkulasi : String = "") -> void:
	var label_tampilan_1 = Label.new()
	var label_tampilan_2 = Label.new()
	label_tampilan_1.text = "Atur nilai "
	label_tampilan_2.text = " menjadi "
	set_variable_name = load("res://ui/blok kode/parameter_input.tscn").instantiate()
	set_variable_name.attached = true
	var _condition_parser := ConditionParser.new()
	var parameter_data : Dictionary = _condition_parser.parse(nama)
	set_variable_name.tentukan_parameter(parameter_data)
	set_variable_name._setup()
	calc_variable_value_by = kalkulasi
	variable_value = load("res://ui/blok kode/parameter_input.tscn").instantiate()
	variable_value.attached = true
	parameter_data = _condition_parser.parse(nilai)
	variable_value.tentukan_parameter(parameter_data)
	variable_value._setup()
	block_type = "Pernyataan"
	header_container.add_child(label_tampilan_1)
	header_container.add_child(set_variable_name)
	header_container.add_child(label_tampilan_2)
	header_container.add_child(variable_value)
	code = hasilkan_kode()
	block_id = EditorKode.tambah_kode(self)
	sesuaikan_warna(EditorKode.warna_blok_pernyataan)
func buat_blok_if(parameter : Dictionary) -> void:
	var label_tampilan = Label.new()
	var input_kondisi = load("res://ui/blok kode/parameter_input.tscn").instantiate()
	logic_elif_blocks = VBoxContainer.new()
	logic_else_block = VBoxContainer.new()
	label_tampilan.text = "Jika "
	header_container.add_child(label_tampilan)
	header_container.add_child(input_kondisi)
	input_kondisi.attached = true
	input_kondisi.tentukan_parameter(parameter)
	input_kondisi._setup()
	block_type = "Logika"
	logic_type = "if"
	logic_input = input_kondisi
	logic_elif_blocks.name = "elif"
	logic_else_block.name = "else"
	$VBoxContainer.add_child(logic_elif_blocks)
	$VBoxContainer.add_child(logic_else_block)
	var logika = hasilkan_kode()
	code = logika
	block_id = EditorKode.tambah_kode(self)
	sesuaikan_warna(EditorKode.warna_blok_logika)
func buat_blok_elif(parameter : Dictionary) -> void:
	var label_tampilan = Label.new()
	var input_kondisi = load("res://ui/blok kode/parameter_input.tscn").instantiate()
	label_tampilan.text = "Atau Jika "
	header_container.add_child(label_tampilan)
	header_container.add_child(input_kondisi)
	input_kondisi.attached = true
	input_kondisi.tentukan_parameter(parameter)
	input_kondisi._setup()
	block_type = "Logika"
	logic_type = "elif"
	logic_input = input_kondisi
	var logika = hasilkan_kode()
	code = logika
	block_id = EditorKode.tambah_kode(self)
	sesuaikan_warna(EditorKode.warna_blok_logika)
func buat_blok_else() -> void:
	var label_tampilan = Label.new()
	label_tampilan.text = "Selain itu"
	header_container.add_child(label_tampilan)
	block_type = "Logika"
	logic_type = "else"
	var logika = hasilkan_kode()
	code = logika
	block_id = EditorKode.tambah_kode(self)
	sesuaikan_warna(EditorKode.warna_blok_logika)

func hasilkan_kode() -> String:
	match block_type:
		"Fungsi":
			var tmp_sub_code : String = ""
			var tmp_indentasi : String = ""
			for hitung_indentasi in indent_level + 1:
				tmp_indentasi += "\t"
			if body_container.get_child_count() > 0:
				for sub_code in body_container.get_children():
					if sub_code is BlokKode:
						tmp_sub_code += "\n" + tmp_indentasi + sub_code.hasilkan_kode()
			else:
				tmp_sub_code = "\n" + tmp_indentasi + "pass"
			return code + tmp_sub_code
		"Instruksi":
			var tmp_code : String = ""
			var tmp_args : Array[String]
			if instruction_object.length() > 0:
				tmp_code += instruction_object + "."
			if instruction_argument.size() > 0:
				for args in instruction_argument:
					tmp_args.append(args.hasilkan_kode())
			tmp_code += instruction_method + "(" + ", ".join(tmp_args) + ")"
			return tmp_code
		"Variabel":
			var tmp_code : String = "var "
			if variable_name != null:
				variable_name.text = variable_name.text.replace(' ', '_')
				tmp_code += variable_name.text
			if variable_type != null:
				tmp_code += " : " + variable_type.dapatkan_tipe()
			if variable_value != null:
				tmp_code += " = " + variable_value.hasilkan_kode()
			return tmp_code
		"Logika":
			var tmp_code : String = ""
			var tmp_sub_code : String = ""
			var tmp_indentasi : String = ""
			var tmp_kode_input : String = ""
			if logic_input != null:
				tmp_kode_input = " " + logic_input.hasilkan_kode()
			tmp_code = logic_type + tmp_kode_input + ":"
			for hitung_indentasi in indent_level + 1:
				tmp_indentasi += "\t"
			if body_container.get_child_count() > 0:
				for sub_code in body_container.get_children():
					if sub_code is BlokKode:
						tmp_sub_code += "\n" + tmp_indentasi + sub_code.hasilkan_kode()
			else:
				tmp_sub_code = "\n" + tmp_indentasi + "pass"
			if logic_elif_blocks != null and logic_elif_blocks.get_child_count() > 0:
				tmp_indentasi = ""
				for hitung_indentasi in indent_level:
					tmp_indentasi += "\t"
				for sub_code in logic_elif_blocks.get_children():
					if sub_code is BlokKode:
						tmp_sub_code += "\n" + tmp_indentasi + sub_code.hasilkan_kode()
			if logic_else_block != null and logic_else_block.get_child_count() > 0:
				tmp_indentasi = ""
				for hitung_indentasi in indent_level:
					tmp_indentasi += "\t"
				if logic_else_block.get_child(0) is BlokKode:
					tmp_sub_code += "\n" + tmp_indentasi + logic_else_block.get_child(0).hasilkan_kode()
			return tmp_code + tmp_sub_code
		"Pernyataan":
			var tmp_code : String = ""
			if set_variable_name != null:
				tmp_code += set_variable_name.hasilkan_kode()
			if variable_value != null:
				tmp_code += " = " + variable_value.hasilkan_kode()
			return tmp_code
	return code

func _parse_argumen(teks: String) -> Array:
	var hasil : Array = []
	var buffer := ""

	var dalam_string := false
	var tipe_string := ""
	var depth_bracket := 0

	for i in teks.length():
		var c = teks[i]

		# ===== HANDLE STRING =====
		if c == "\"" or c == "'":
			if dalam_string and c == tipe_string:
				dalam_string = false
			elif !dalam_string:
				dalam_string = true
				tipe_string = c

			buffer += c
			continue

		# ===== HANDLE BRACKET =====
		if !dalam_string:
			if c == "[":
				depth_bracket += 1
			elif c == "]":
				depth_bracket -= 1

		# ===== SPLIT SAAT KOMA VALID =====
		if c == "," and !dalam_string and depth_bracket == 0:
			hasil.append(buffer.strip_edges())
			buffer = ""
			continue

		buffer += c

	# Tambahkan sisa buffer terakhir
	if buffer.strip_edges() != "":
		hasil.append(buffer.strip_edges())

	return hasil
func _dapatkan_induk() -> Control:
	if get_parent() is DaftarBlokKode:
		return get_parent()
	elif get_parent() is AreaBlokKode:
		return get_parent()
	elif get_parent() is VBoxContainer:
		if get_parent().name == "Body":
			return get_node("../../../../").get_parent()
		elif get_parent().name in ["elif", "else"]:
			return get_node("../../").get_parent()
	return get_parent().get_parent().get_parent()
