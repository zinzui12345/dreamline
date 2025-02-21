@tool
extends MarginContainer

#const BlockCodePlugin = preload("res://addons/block_code/block_code_plugin.gd")

signal node_name_changed(node_name: String)

@onready var _block_code_icon = load("res://skrip/editor kode/block_code_node/block_code_node.svg") as Texture2D
#@onready var _editor_inspector: EditorInspector = EditorInterface.get_inspector()
#@onready var _editor_selection: EditorSelection = EditorInterface.get_selection()
@onready var _node_option_button: OptionButton = %NodeOptionButton


func _ready():
	_node_option_button.connect("item_selected", _on_node_option_button_item_selected)


func scene_selected(scene_root: Node):
	_update_node_option_button_items()
	#var current_block_code = _editor_inspector.get_edited_object() as BlockCode
	#if not current_block_code:
	#	block_script_selected(null)

func block_code_selected(block_code : Node):
	if block_code == null: 
		_node_option_button.clear()
		for dummy_block_code in $dummy_script.get_children():
			dummy_block_code.queue_free()
		return
	_node_option_button.add_item("{name} ({type})".format({"name": dunia.get_path_to(block_code).get_concatenated_names(), "type": block_code.block_script.script_inherits}))
	_node_option_button.set_item_metadata(0, block_code)

func block_script_selected(block_script: BlockScriptSerialization):
	# TODO: We should listen for property changes in all BlockCode nodes and
	#       their parents. As a workaround for the UI displaying stale data,
	#       we'll crudely update the list of BlockCode nodes whenever the
	#       selection changes.

	_update_node_option_button_items(block_script)

	var select_index = _get_block_script_index(block_script)
	# FIXME : kode_ubahan custom urutan ke 2 terhapus
	# root.get_node("editor_kode/blok_kode/MarginContainer/HBoxContainer/ScriptVBox/HBoxContainer/TitleBar/dummy_script").get_children()
	if _node_option_button.selected != select_index:
		_node_option_button.select(select_index)


func _update_node_option_button_items(block_script = null):
	#_node_option_button.clear() # jangan lakuin ini!

	#var scene_root = false # EditorInterface.get_edited_scene_root()

	#if not scene_root:
	#	return

	#for block_code in BlockCodePlugin.list_block_code_nodes_for_node(scene_root, true):
		#if not BlockCodePlugin.is_block_code_editable(block_code):
			#continue
#
		#var node_item_index = _node_option_button.item_count
		#var node_label = "{name} ({type})".format({"name": scene_root.get_path_to(block_code).get_concatenated_names(), "type": block_code.block_script.script_inherits})
		#_node_option_button.add_item(node_label)
		#_node_option_button.set_item_icon(node_item_index, _block_code_icon)
		#_node_option_button.set_item_metadata(node_item_index, block_code)
	
	# 17/02/25 :: muat setiap aset kode yang memiliki kelas yang sama
	if block_script != null:
		#Panku.notify("memuat kode kustom...")
		for aset_ in server.permainan.daftar_aset:
			var objekk : Dictionary = server.permainan.daftar_aset[aset_]
			if objekk.tipe == "kode":
				if objekk.has("kelas") and objekk.kelas == block_script.script_inherits:
					var block_code : BlockCode = load(objekk.sumber).instantiate()
					for kelas in ProjectSettings.get_global_class_list():
						if kelas.class == objekk.kelas and ClassDB.can_instantiate(objekk.kelas):
							var skrip = load(kelas.path)
							var node = skrip.new()
							var node_item_index = _node_option_button.item_count
							var node_label = "{name} ({type})".format({"name": objekk.sumber, "type": block_code.block_script.script_inherits})
							_node_option_button.add_item(node_label)
							_node_option_button.set_item_icon(node_item_index, _block_code_icon)
							_node_option_button.set_item_metadata(node_item_index, block_code)
							block_code.process_mode = PROCESS_MODE_DISABLED
							node.process_mode = PROCESS_MODE_DISABLED
							node.name = "kode_ubahan_kustom_" + str(node_item_index)
							node.add_child(block_code)
							$dummy_script.add_child(node)
	#else:
	#	Panku.notify("error")


func _get_block_script_index(block_script: BlockScriptSerialization) -> int:
	for index in range(_node_option_button.item_count):
		var block_code_node = _node_option_button.get_item_metadata(index)
		if block_code_node.block_script == block_script:
			return index
	return -1


func _on_node_option_button_item_selected(index):
	if is_instance_valid(_node_option_button.get_item_metadata(index)):
		var block_code_node = _node_option_button.get_item_metadata(index) as BlockCode
		var parent_node = block_code_node.get_parent() as Node
		
		# TODO: *
		# simpan kode asli node di suatu variabel pada client dan server
		# gunakan id aset kode untuk membandingkan apakah node menggunakan kode aset atau kode aslinya
		# jika tidak menggunakan kode asli, sesuaikan indeks kode yang terpilih
		
		# 20/02/25 :: cukup yang simpel aja, ganti di block_code node dan main_panel dengan block_code_node
		_node_option_button.clear()
		server.permainan._ketika_mengganti_kode_objek(block_code_node)
		
		#_editor_selection.clear()
		#_editor_selection.add_node(block_code_node)
		#if parent_node:
		#	_editor_selection.add_node(parent_node)
	else:
		server.permainan._tampilkan_popup_informasi_("NULL")
