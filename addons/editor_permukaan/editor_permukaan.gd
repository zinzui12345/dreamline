@tool
extends EditorPlugin

const SCRIPT_PERMUKAAN := "res://skrip/entitas/permukaan.gd"
const KURSOR_SCENE := preload("res://skena/kursor_objek.scn")

var toggle_button: Button
var is_active := false
var _editing_node: Node
var _cursor: Node3D


func _enter_tree():
	toggle_button = Button.new()
	toggle_button.text = "Terrain"
	toggle_button.flat = false
	toggle_button.toggle_mode = true
	toggle_button.tooltip_text = "Mode edit ketinggian — klik pada permukaan untuk mengubah tinggi"
	toggle_button.toggled.connect(_on_toggled)
	add_control_to_container(CONTAINER_SPATIAL_EDITOR_MENU, toggle_button)


func _exit_tree():
	_hapus_kursor()
	if toggle_button:
		remove_control_from_container(CONTAINER_SPATIAL_EDITOR_MENU, toggle_button)
		toggle_button.queue_free()
		toggle_button = null


func _handles(object: Object) -> bool:
	var s = object.get_script()
	return s != null and s.get_path() == SCRIPT_PERMUKAAN


func _edit(object: Object):
	_editing_node = object if object is Node else null
	if _cursor:
		if _editing_node and _cursor.get_parent() != _editing_node:
			if _cursor.get_parent():
				_cursor.get_parent().remove_child(_cursor)
			_editing_node.add_child(_cursor)
			_cursor.set_owner(null)
		elif _editing_node == null and _cursor.get_parent():
			_cursor.get_parent().remove_child(_cursor)


func _on_toggled(toggled_on: bool):
	is_active = toggled_on
	if is_active:
		_buat_kursor()
	else:
		if _cursor:
			_cursor.visible = false


func _buat_kursor():
	if _cursor != null:
		_cursor.visible = true
		return

	var terrain = _editing_node if is_instance_valid(_editing_node) else _cari_permukaan()
	if terrain == null:
		return

	_cursor = KURSOR_SCENE.instantiate()
	_cursor.name = "@kursor_editor_permukaan"
	_cursor.visible = false
	terrain.add_child(_cursor)
	_cursor.set_owner(null)


func _hapus_kursor():
	if _cursor:
		if _cursor.get_parent():
			_cursor.get_parent().remove_child(_cursor)
		_cursor.queue_free()
		_cursor = null


func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	if not is_active:
		return AFTER_GUI_INPUT_PASS

	if event is InputEventMouseMotion:
		var terrain = _editing_node if is_instance_valid(_editing_node) else _cari_permukaan()
		if terrain == null:
			return AFTER_GUI_INPUT_PASS

		var hit_pos = _raycast_dari_pos(camera, event.position)
		if hit_pos != null and _cursor:
			if terrain.has_method("_snap_vertex"):
				hit_pos = terrain._snap_vertex(hit_pos)
			_cursor.global_position = hit_pos
			_cursor.visible = true
		elif _cursor:
			_cursor.visible = false
		return AFTER_GUI_INPUT_PASS

	if event is InputEventMouseButton and event.pressed:
		var terrain = _editing_node if is_instance_valid(_editing_node) else _cari_permukaan()
		if terrain == null:
			return AFTER_GUI_INPUT_STOP

		var hit_pos = _raycast_dari_pos(camera, event.position)
		if hit_pos == null:
			return AFTER_GUI_INPUT_STOP

		match event.button_index:
			MOUSE_BUTTON_LEFT:
				terrain._atur_dari_world(hit_pos)
			MOUSE_BUTTON_RIGHT:
				if terrain.has_method("_reset_dari_world"):
					terrain._reset_dari_world(hit_pos)
		return AFTER_GUI_INPUT_STOP

	return AFTER_GUI_INPUT_PASS


func _raycast_dari_pos(camera: Camera3D, mouse_pos: Vector2):
	var origin = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	var end = origin + direction * 10000.0

	var terrain = _editing_node if is_instance_valid(_editing_node) else _cari_permukaan()
	if terrain == null:
		return null

	var space = terrain.get_world_3d().direct_space_state
	if space:
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		var result = space.intersect_ray(query)
		if result and result.has("position"):
			return result["position"]

	if direction.y == 0:
		return null
	var t = -origin.y / direction.y
	return origin + direction * t


func _cari_permukaan():
	var root = get_editor_interface().get_edited_scene_root()
	if root:
		return _cari_di_pohon(root)
	return null


func _cari_di_pohon(node: Node) -> Node:
	if _adalah_permukaan(node):
		return node
	for child in node.get_children():
		var found = _cari_di_pohon(child)
		if found:
			return found
	return null


func _adalah_permukaan(node: Node) -> bool:
	var s = node.get_script()
	return s != null and s.get_path() == SCRIPT_PERMUKAAN
