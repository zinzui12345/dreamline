extends PanelContainer
class_name AreaParameter

@export_enum("Boolean", "Number", "String", "Array", "Dictionary", "Object", "Variant") var accept_type = "bool"
@export var parameter_input_node : NodePath
@export var parameter_input_property : String

func _notification(notification_type):
	match notification_type:
		NOTIFICATION_DRAG_BEGIN:
			if get_child_count() == 0:
				show()
		NOTIFICATION_DRAG_END:
			if get_child_count() == 0:
				hide()

func _can_drop_data(_at_position, data) -> bool:
	if get_child_count() == 0 and data is BlokParameter:
		match accept_type:
			"Boolean":
				if data.data_type == "bool":
					return true
			"Number":
				if data.data_type in ["int", "float"]:
					return true
			"String", "Array", "Dictionary", "Object":
				if data.data_type == accept_type:
					return true
			"Variant":
				return true
	return false

func _drop_data(_at_position, data):
	if (not parameter_input_node.is_empty() and parameter_input_property.length() > 0):
		var source_parent : Node = data.get_parent()
		if source_parent is AreaParameter:
			source_parent.remove_child(data)
			if (not source_parent.parameter_input_node.is_empty() and source_parent.parameter_input_property.length() > 0):
				source_parent.get_node(source_parent.parameter_input_node).set(source_parent.parameter_input_property, null)
		elif source_parent is DaftarBlokKode:
			data = data.duplicate()
		add_child(data)
		get_node(parameter_input_node).set(parameter_input_property, data)
	else:
		Panku.notify("Node input belum diatur!")
