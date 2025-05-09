extends Object

const BlockDefinition = preload("res://skrip/editor kode/code_generation/block_definition.gd")
const Types = preload("res://skrip/editor kode/types/types.gd")
const Util = preload("res://skrip/editor kode/code_generation/util.gd")

const _BLOCKS_PATH = "res://skrip/editor kode/blocks/"

const _FALLBACK_SET_FOR_TYPE = {
	TYPE_BOOL: false,
	TYPE_INT: 0,
	TYPE_FLOAT: 0.0,
	TYPE_VECTOR2: Vector2(0, 0),
	TYPE_VECTOR3: Vector3(0, 0, 0),
	TYPE_COLOR: Color.DARK_ORANGE,
	TYPE_ARRAY: [],
	TYPE_STRING: "",
}

const _FALLBACK_CHANGE_FOR_TYPE = {
	TYPE_BOOL: true,
	TYPE_INT: 1,
	TYPE_FLOAT: 1.0,
	TYPE_VECTOR2: Vector2(1, 1),
	TYPE_VECTOR3: Vector3(1, 1, 1),
	TYPE_ARRAY: ["ProgrammerIndonesia44","dreamline"],
	TYPE_COLOR: Color.DARK_ORANGE,
	TYPE_STRING: "godot",
}

const _SETTINGS_FOR_CLASS_PROPERTY = {
	#"npc_ai":
	#{
		#"nyawa":
		#{
			#"category": "%variabel%",
			#"default_set": 100,
		#}
	#},
	#"Node3D":
	#{
		#"rotation_degrees":
		#{
			#"category": "Transform | Rotation",
			#"default_set": Vector3(0, 45, 0)
		#},
		#"scale":
		#{
			#"category": "Transform | Scale",
			#"default_set": Vector3(1, 1, 1),
			#"default_change": Vector3(0.1, 0.1, 0.1),
		#},
	#},
	"CanvasItem":
	{
		"modulate":
		{
			"category": "Graphics | Modulate",
			"has_change": false,
		},
		"visible":
		{
			"category": "Graphics | Visibility",
			"has_change": false,
		},
	},
	"RigidBody2D":
	{
		"mass": {"category": "Physics | Mass"},
		"linear_velocity": {"category": "Physics | Velocity"},
		"angular_velocity": {"category": "Physics | Velocity"},
	},
	"AudioStreamPlayer":
	{
		"stream_paused":
		{
			"category": "Sounds",
			"has_change": false,
		},
	},
	"CharacterBody2D":
	{
		"velocity": {"category": "Physics | Velocity"},
	},
}

static var _catalog: Dictionary
static var _by_class_name: Dictionary
static var _custom_blocks: Array[String]
static var _current_class: String

static func _setup_definitions_from_files():
	var definition_files = Util.get_files_in_dir_recursive(_BLOCKS_PATH, "*.tres")
	for file in definition_files:
		var block_definition: BlockDefinition = load(file)
		_catalog[block_definition.name] = block_definition
		var target = block_definition.target_node_class
		if not target:
			continue
		if not target in _by_class_name:
			_by_class_name[target] = {}
		_by_class_name[target][block_definition.name] = block_definition


static func _add_property_definitions(_class_name: String, property_list: Array[Dictionary], property_settings: Dictionary):
	for property in property_list:
		if not property.name in property_settings:
			continue
		var block_settings = property_settings[property.name]
		var type_string: String = Types.VARIANT_TYPE_TO_STRING[property.type]

		if not _class_name in _by_class_name:
			_by_class_name[_class_name] = {}

		# Setter
		var block_definition: BlockDefinition = (
			BlockDefinition
			. new(
				&"%s_set_%s" % [_class_name, property.name],
				_class_name,
				str(TranslationServer.translate("%deskripsi_atur_properti%")) % property.name,
				block_settings.category,
				Types.BlockType.STATEMENT,
				TYPE_NIL,
				str(TranslationServer.translate("%atur_properti")) % [property.name.capitalize(), type_string],
				"%s = {nilai}" % property.name,
				{"nilai": block_settings.get("default_set", _FALLBACK_SET_FOR_TYPE[property.type])},
			)
		)
		_catalog[block_definition.name] = block_definition
		_by_class_name[_class_name][block_definition.name] = block_definition

		# Changer
		if block_settings.get("has_change", true):
			block_definition = (
				BlockDefinition
				. new(
					&"%s_change_%s" % [_class_name, property.name],
					_class_name,
					str(TranslationServer.translate("%deskripsi_ubah_properti%")) % property.name,
					block_settings.category,
					Types.BlockType.STATEMENT,
					TYPE_NIL,
					str(TranslationServer.translate("%ubah_properti")) % [property.name.capitalize(), type_string],
					"%s += {nilai}" % property.name,
					{"nilai": block_settings.get("default_change", _FALLBACK_CHANGE_FOR_TYPE[property.type])},
				)
			)
		_catalog[block_definition.name] = block_definition
		_by_class_name[_class_name][block_definition.name] = block_definition

		# Getter
		block_definition = (
			BlockDefinition
			. new(
				&"%s_get_%s" % [_class_name, property.name],
				_class_name,
				str(TranslationServer.translate("%deskripsi_dapatkan_properti%")) % property.name,
				block_settings.category,
				Types.BlockType.VALUE,
				property.type,
				"%s" % property.name.capitalize(),
				"%s" % property.name,
			)
		)
		_catalog[block_definition.name] = block_definition
		_by_class_name[_class_name][block_definition.name] = block_definition


static func _get_inputmap_actions() -> Array[StringName]:
	var inputmap_actions: Array[StringName]

	var editor_input_actions: Dictionary = {}
	var editor_input_action_deadzones: Dictionary = {}
	if Engine.is_editor_hint():
		var actions := InputMap.get_actions()
		for action in actions:
			if action.begins_with("spatial_editor"):
				var events := InputMap.action_get_events(action)
				editor_input_actions[action] = events
				editor_input_action_deadzones[action] = InputMap.action_get_deadzone(action)

	InputMap.load_from_project_settings()

	inputmap_actions = InputMap.get_actions()

	if Engine.is_editor_hint():
		for action in editor_input_actions.keys():
			InputMap.add_action(action, editor_input_action_deadzones[action])
			for event in editor_input_actions[action]:
				InputMap.action_add_event(action, event)

	return inputmap_actions


static func _setup_properties_for_class():
	for _class_name in _SETTINGS_FOR_CLASS_PROPERTY:
		var property_list = ClassDB.class_get_property_list(_class_name, true)
		var property_settings = _SETTINGS_FOR_CLASS_PROPERTY[_class_name]
		_add_property_definitions(_class_name, property_list, property_settings)


static func _setup_input_block():
	var inputmap_actions = _get_inputmap_actions()

	var block_definition: BlockDefinition = (
		BlockDefinition
		. new(
			&"is_input_actioned",
			"",
			"",
			"%masukan%",
			Types.BlockType.VALUE,
			TYPE_BOOL,
			"%apakah_aksi {action_name: OPTION} {action: OPTION}",
			'Input.is_action_{action}("{action_name}")',
			{"action_name": OptionData.new(inputmap_actions), "action": OptionData.new(["pressed", "just_pressed", "just_released"])},
		)
	)
	_catalog[block_definition.name] = block_definition


static func setup():
	if _catalog:
		return

	_catalog = {}
	_setup_definitions_from_files()
	_setup_properties_for_class()
	_setup_input_block()


static func get_block(block_name: StringName):
	return _catalog.get(block_name)


static func has_block(block_name: StringName):
	return block_name in _catalog


static func get_blocks_by_class(_class_name: String):
	if not _class_name in _by_class_name:
		return []
	var block_definitions = _by_class_name[_class_name] as Dictionary
	return block_definitions.values()


static func add_custom_blocks(
	_class_name,
	block_definitions: Array[BlockDefinition] = [],
	property_list: Array[Dictionary] = [],
	property_settings: Dictionary = {},
):
	setup()

	if not _class_name in _by_class_name:
		_by_class_name[_class_name] = {}

	_current_class = _class_name

	for block_definition in block_definitions:
		_custom_blocks.append(block_definition.name)
		_catalog[block_definition.name] = block_definition
		_by_class_name[_class_name][block_definition.name] = block_definition

	_add_property_definitions(_class_name, property_list, property_settings)
