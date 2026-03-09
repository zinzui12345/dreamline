extends BlokParameter
class_name ParameterInput

@export var input_block : Node :
	set(node):
		if $input_block.get_child_count() == 1 and node != null:
			$MarginContainer/default_value.visible = false
			input_block = $input_block.get_child(0)
		else:
			if node != null:
				$MarginContainer/default_value.visible = false
				$input_block.visible = true
				$input_block.add_child(node)
			else:
				$MarginContainer/default_value.visible = true
				$input_block.visible = false
				if input_block != null and input_block.get_parent() == $input_block:
					$input_block.remove_child(input_block)
				match data_type:
					"bool":		_sesuaikan_warna(Color("789bffff"))
					"int":		_sesuaikan_warna(Color("ffb107ff"))
					"float":	_sesuaikan_warna(Color("ffb107ff"))
					"String":	_sesuaikan_warna(Color("ae78ffff"))
					"Array":	pass
					"Variable":	_sesuaikan_warna(Color("ff1500ff"))
			input_block = node
@export var blok_kode : BlokKode

func _setup() -> void:
	if attached:
		$MarginContainer.remove_theme_constant_override("margin_left")
	for default_value_display in $MarginContainer/default_value.get_children():
		if default_value_display.name == data_type:
			default_value_display.visible = true
		else:
			default_value_display.visible = false

func _sesuaikan_warna(warna : Color) -> void:
	set("theme_override_styles/panel", get("theme_override_styles/panel").duplicate())
	get("theme_override_styles/panel").set("bg_color", warna)

func tentukan_parameter(parameter : Dictionary) -> void:
	print_debug(parameter)
	match parameter["type"]:
		"compare":			input_block = load("res://ui/blok kode/parameter_perbandingan.tscn").instantiate()
		"compare_variant":	input_block = load("res://ui/blok kode/parameter_perbandingan_tipe_data.tscn").instantiate()
		"and", "or":		input_block = load("res://ui/blok kode/parameter_logika.tscn").instantiate()
		"arithmetic":		input_block = load("res://ui/blok kode/parameter_aritmatika.tscn").instantiate()
		"identifier":
			if EditorKode.cek_apakah_variabel_sudah_ada(parameter["value"]):
				_tentukan_pilihan_variabel_berdasarkan_tipe(parameter["value"])
				parameter["type"] = "Variable"
	if input_block is BlokParameter:
		data_type = input_block.data_type
		input_block.tentukan_parameter(parameter)
	if input_block == null:
		match parameter["type"]:
			"bool":
				if parameter.has("value"):
					match parameter["value"]:
						"false":	$MarginContainer/default_value/bool.select(0)
						"true":		$MarginContainer/default_value/bool.select(1)
				$input_block.accept_type = "Boolean"
				_sesuaikan_warna(Color("789bffff"))
			"int":
				if parameter.has("value"):
					$MarginContainer/default_value/int.value = int(parameter["value"])
				$input_block.accept_type = "Number"
				_sesuaikan_warna(Color("ffb107ff"))
			"float":
				if parameter.has("value"):
					$MarginContainer/default_value/float.value = float(parameter["value"])
				$input_block.accept_type = "Number"
				_sesuaikan_warna(Color("ffb107ff"))
			"String":
				if parameter.has("value"):
					$MarginContainer/default_value/String.text = parameter["value"].substr(1, parameter["value"].length()-2)
				$input_block.accept_type = "String"
				_string_diubah()
				_sesuaikan_warna(Color("ae78ffff"))
			"Array":
				pass
			"Variable":
				_sesuaikan_warna(Color("ff1500ff"))
		data_type = parameter["type"]

func hasilkan_kode() -> String:
	if input_block != null:
		return input_block.hasilkan_kode()
	else:
		match data_type:
			"bool":
				match $MarginContainer/default_value/bool.selected:
					0:	return "(false)"
					1:	return "(true)"
			"int":
				return str(int($MarginContainer/default_value/int.value))
			"float":
				return str($MarginContainer/default_value/float.value)
			"String":
				var result_text : String
				result_text = $MarginContainer/default_value/String.text.replace("\n", "\\n")
				result_text = result_text.replace("\t", "\\t")
				return "\"" + result_text + "\""
			"Array":
				return $MarginContainer/default_value/Array.text
			"Variable":
				if input_block == null:
					if $MarginContainer/default_value/Variable.selected < 0:
						return "# _"
					else:
						return $MarginContainer/default_value/Variable.get_item_text($MarginContainer/default_value/Variable.selected)
				else:
					# TODO : ambil dari blok variabel
					return "# belum di implementasi"
		return "null"

func _string_diubah() -> void:
	var jumlah_baris : int = $MarginContainer/default_value/String.get_line_count()
	var lebar_maks : float = 0.0
	
	for i in jumlah_baris:
		var lebar = $MarginContainer/default_value/String.get_line_width(i)
		if lebar > lebar_maks:
			lebar_maks = lebar
	
	custom_minimum_size.x = clamp(lebar_maks + 10, 100, 500)
func _tentukan_pilihan_variabel_berdasarkan_tipe(nama_variabel : String) -> void:
	var data_variabel = EditorKode.dapatkan_variabel(nama_variabel)
	var tipe_variabel : String = data_variabel["tipe"]
	var daftar_variabel_yang_dapat_dipilih = EditorKode.dapatkan_daftar_variabel_berdasarkan_tipe(tipe_variabel)
	if $MarginContainer/default_value/Variable.item_count > 0:
		$MarginContainer/default_value/Variable.select(-1)
		$MarginContainer/default_value/Variable.clear()
	for id_variabel_pilihan in daftar_variabel_yang_dapat_dipilih:
		var nama_variabel_saat_ini : String = daftar_variabel_yang_dapat_dipilih[id_variabel_pilihan]["nama"]
		$MarginContainer/default_value/Variable.add_item(nama_variabel_saat_ini)
		if nama_variabel_saat_ini == nama_variabel:
			$MarginContainer/default_value/Variable.select($MarginContainer/default_value/Variable.item_count - 1)
		EditorKode.daftar_penggunaan_variabel(id_variabel_pilihan, self)
	if blok_kode != null and blok_kode.variable_value != null:
		# FIXME : kalau blok_kode.input_block != null, hapus blok input
		blok_kode.variable_value.tentukan_parameter({
			"type":	tipe_variabel
		})
		if tipe_variabel != "String":
			blok_kode.variable_value.custom_minimum_size.x = 100
		blok_kode.variable_value._setup()
func _dapatkan_nama_variabel_dipilih() -> String:
	# if input_block == null:
	return $MarginContainer/default_value/Variable.get_item_text($MarginContainer/default_value/Variable.selected)
	# else:
	# TODO : lakukan di blok variabel
func _ubah_nama_variabel(nama_lama : String, nama_baru : String) -> void:
	if input_block == null:
		for item_id in $MarginContainer/default_value/Variable.item_count:
			if $MarginContainer/default_value/Variable.get_item_text(item_id) == nama_lama:
				$MarginContainer/default_value/Variable.set_item_text(item_id, nama_baru)
	else:
		# TODO : lakukan di blok variabel
		pass
