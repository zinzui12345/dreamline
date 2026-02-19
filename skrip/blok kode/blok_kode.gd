extends PanelContainer
class_name BlokKode

# Tipe blok: COMMAND, IF, WHILE
@export_enum("Fungsi", "Variabel", "Pernyataan", "Logika", "Instruksi") var block_type = "Fungsi"
@export var use_once : bool = false
@export var locked : bool = false
@export var code : String = ""
@export var indent_level : int = 0
@export var inherit_class : String = ""
@onready var header_container = $VBoxContainer/Header
@onready var body_container = $VBoxContainer/HBoxContainer/Body

# Instruksi
@export var instruction_object : String = ""
@export var instruction_method : String = ""
@export var instruction_argument : Array[Node]

# Logika
@export var logic_input : Node

const EditorKode = preload("res://skrip/blok kode/editor_kode.gd")

var block_id : int = -1

func _setup():
	# Sembunyikan body jika bukan IF atau WHILE
	if block_type not in ["Fungsi", "Logika"]:
		body_container.hide()
	# Sesuaikan indentasi berdasarkan blok di atasnya
	var parent = get_parent()
	var sibling_atas = parent.get_child(get_index() - 1) if get_index() > 0 else null
	if sibling_atas != null and indent_level > sibling_atas.indent_level:
		parent.remove_child(self)
		sibling_atas.body_container.add_child(self)
		if (indent_level - sibling_atas.indent_level) > 1:
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
		elif data.block_type == "Logika" and block_type != "Variabel":
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
		indent_level = induk.indent_level + 1
	if body_container.get_child_count() > 0:
		for sub_code in body_container.get_children():
			if sub_code is BlokKode:
				sub_code.sesuaikan_indentasi()

func buat_blok_extends(nama_kelas : String) -> void:
	var label_tampilan = Label.new()
	var instruksi = "extends " + nama_kelas
	label_tampilan.text = "Mewarisi " + nama_kelas
	code = instruksi
	locked = true
	block_type = "Pernyataan"
	block_id = EditorKode.tambah_kode(instruksi)
	header_container.add_child(label_tampilan)
func buat_blok_fungsi(nama_fungsi : String, parameter : String) -> void:
	var label_tampilan = Label.new()
	var instruksi = "func " + nama_fungsi + "(" + parameter + "):"
	label_tampilan.text = "Ketika " + nama_fungsi
	code = instruksi
	use_once = true
	block_id = EditorKode.tambah_kode(instruksi)
	header_container.add_child(label_tampilan)
func buat_blok_instruksi(target_objek : String, metode : String, argumen : String) -> void:
	var label_tampilan = Label.new()
	var daftar_argumen : Array = _parse_argumen(argumen)
	label_tampilan.text = "Panggil " + metode + " pada " + target_objek + " dengan "
	header_container.add_child(label_tampilan)
	for data_argumen in daftar_argumen:
		print("Argumen hasil parsing:", data_argumen)
		instruction_argument = []
		if data_argumen.begins_with('"') and data_argumen.ends_with('"'):
			var input_argumen = load("res://ui/blok kode/blok_argumen.tscn").instantiate()
			input_argumen.atur("String", data_argumen.substr(1, data_argumen.length() - 2))
			header_container.add_child(input_argumen)
			instruction_argument.append(input_argumen)
	instruction_object = target_objek
	instruction_method = metode
	block_type = "Instruksi"
	var instruksi = hasilkan_kode()
	code = instruksi
	block_id = EditorKode.tambah_kode(instruksi)
func buat_blok_if(parameter : Dictionary) -> void:
	var label_tampilan = Label.new()
	var input_kondisi = load("res://ui/blok kode/parameter_kondisi.tscn").instantiate()
	label_tampilan.text = "Jika "
	header_container.add_child(label_tampilan)
	header_container.add_child(input_kondisi)
	input_kondisi.attached = true
	input_kondisi.tentukan_parameter(parameter)
	block_type = "Logika"
	logic_input = input_kondisi
	var logika = hasilkan_kode()
	code = logika
	block_id = EditorKode.tambah_kode(logika)

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
					tmp_args.append(args.dapatkan_nilai())
			tmp_code += instruction_method + "(" + ", ".join(tmp_args) + ")"
			return tmp_code
		"Logika":
			var tmp_code : String = ""
			var tmp_sub_code : String = ""
			var tmp_indentasi : String = ""
			tmp_code = "if " + logic_input.hasilkan_kode() + ":"
			for hitung_indentasi in indent_level + 1:
				tmp_indentasi += "\t"
			if body_container.get_child_count() > 0:
				for sub_code in body_container.get_children():
					if sub_code is BlokKode:
						tmp_sub_code += "\n" + tmp_indentasi + sub_code.hasilkan_kode()
			else:
				tmp_sub_code = "\n" + tmp_indentasi + "pass"
			return tmp_code + tmp_sub_code
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
	elif get_parent() is VBoxContainer and get_parent().name == "Body":
		return get_node("../../../").get_parent()
	else:
		return get_parent().get_parent()
