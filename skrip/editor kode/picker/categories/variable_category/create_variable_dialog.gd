@tool
extends ConfirmationDialog

#const BlockCodePlugin = preload("res://addons/block_code/block_code_plugin.gd")

signal create_variable(var_name: String, var_type: String)

@onready var _variable_input := %VariableInput
@onready var _type_option := %TypeOption
@onready var _messages := %Messages

const available_types = ["STRING", "BOOL", "INT", "FLOAT", "ARRAY", "VECTOR2", "VECTOR3", "COLOR"]


func _ready():
	_type_option.clear()

	for type in available_types:
		_type_option.add_item(type)

	check_errors(_variable_input.text)


func _clear():
	_variable_input.text = ""
	check_errors(_variable_input.text)
	_type_option.select(0)


func _on_variable_input_text_changed(new_text):
	get_ok_button().disabled = check_errors(new_text)


func check_errors(new_var_name: String) -> bool:
	if new_var_name.contains(" "):
		var caret_column = _variable_input.caret_column
		new_var_name = new_var_name.replace(" ", "_")
		_variable_input.text = new_var_name
		_variable_input.caret_column = caret_column

	_messages.clear()

	var errors: Array = []

	if new_var_name == "":
		errors.append(TranslationServer.translate("%kesalahan_variabel_tanpa_nama%"))
	elif new_var_name == "_":
		errors.append(TranslationServer.translate("%kesalahan_variabel_garis_bawah%"))
	elif RegEx.create_from_string("^[0-9]").search(new_var_name) != null:
		errors.append(TranslationServer.translate("%kesalahan_variabel_dimulai_angka%"))

	if new_var_name.begins_with("__"):
		errors.append(TranslationServer.translate("%kesalahan_variabel_2_garis_bawah%"))

	if RegEx.create_from_string("[^_a-zA-Z0-9-]+").search(new_var_name) != null:
		errors.append(TranslationServer.translate("%kesalahan_variabel_simbol%"))

	var duplicate_variable_name := false
	var current_block_code = get_tree().get_root().get_node("Dreamline/editor_kode/blok_kode")._current_block_code_node
	if current_block_code:
		var current_block_script = current_block_code.block_script
		if current_block_script:
			for variable in current_block_script.variables:
				if variable.var_name == new_var_name:
					duplicate_variable_name = true
					break

	if duplicate_variable_name:
		errors.append(TranslationServer.translate("%kesalahan_variabel_duplikat%"))

	if errors.is_empty():
		_messages.push_context()
		_messages.push_color(Color("73F27F"))
		_messages.push_list(0, RichTextLabel.LIST_DOTS, false)

		_messages.add_text(str(TranslationServer.translate("%membuat_variabel_baru%")) % [new_var_name])

		_messages.pop_context()

		return false
	else:
		_messages.push_context()
		_messages.push_color(Color("FF786B"))
		_messages.push_list(0, RichTextLabel.LIST_DOTS, false)

		for error in errors:
			_messages.add_text(error)
			_messages.newline()

		_messages.pop_context()

		return true


func _on_confirmed():
	if not check_errors(_variable_input.text):
		create_variable.emit(_variable_input.text, _type_option.get_item_text(_type_option.selected))
	_clear()


func _on_canceled():
	_clear()
