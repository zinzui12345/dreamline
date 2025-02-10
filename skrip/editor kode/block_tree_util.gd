extends Object

const InstructionTree = preload("res://skrip/editor kode/instruction_tree/instruction_tree.gd")


static func generate_script_from_nodes(nodes: Array[Node], block_script: BlockScriptSerialization) -> String:
	var entry_blocks_by_entry_statement: Dictionary = {}
	var entry_variable_set_statement: Dictionary = {}

	for block in nodes:
		if !(block is Block):
			continue

		if block is EntryBlock:
			var regex = RegEx.new()
			regex.compile("onset_var_*")
			if regex.search(block.block_name):
				entry_variable_set_statement[block.block_name] = block
			else:
				var entry_statement = block.get_entry_statement()
				if not entry_blocks_by_entry_statement.has(entry_statement):
					entry_blocks_by_entry_statement[entry_statement] = []
				entry_blocks_by_entry_statement[entry_statement].append(block)

	var script: String = ""
	var extend_class = block_script.script_inherits

	if type_exists("placeholder_" + extend_class):
		extend_class = "placeholder_" + extend_class
		Panku.notify(extend_class)
	else:
		Panku.notify("kelas nggak ada")

	script += "extends %s\n\n" % extend_class

	var init_func = InstructionTree.TreeNode.new("func _init():")

	for variable in block_script.variables:
		script += "var %s: %s" % [variable.var_name, type_string(variable.var_type)]
		if entry_variable_set_statement.has("onset_var_" + variable.var_name):
			var setter_block : EntryBlock = entry_variable_set_statement["onset_var_" + variable.var_name]
			var setter_script : String = _generate_script_from_entry_blocks(setter_block.get_entry_statement(), [setter_block], init_func)
			var indent_script : String
			var split_line = setter_script.split("\n")
			for line in split_line:
				if line == "\tpass" or line == "": pass
				else: indent_script += "\t" + line + "\n"
			script += ":\n%s\t\t%s = nilai_%s\n" % [indent_script, variable.var_name, variable.var_name]
		else:
			script += "\n"

	script += "\n"

	for entry_statement in entry_blocks_by_entry_statement:
		var entry_blocks: Array[EntryBlock]
		entry_blocks.assign(entry_blocks_by_entry_statement[entry_statement])
		script += _generate_script_from_entry_blocks(entry_statement, entry_blocks, init_func)

	if init_func.children:
		script += InstructionTree.generate_text(init_func)

	return script


static func _generate_script_from_entry_blocks(entry_statement: String, entry_blocks: Array[EntryBlock], init_func: InstructionTree.TreeNode) -> String:
	var script = entry_statement + "\n"
	var signal_node: InstructionTree.TreeNode
	var is_empty = true

	InstructionTree.IDHandler.reset()

	for entry_block in entry_blocks:
		var next_block := entry_block.bottom_snap.get_snapped_block()

		if next_block != null:
			var instruction_node: InstructionTree.TreeNode = next_block.get_instruction_node()
			var to_append := InstructionTree.generate_text(instruction_node, 1)
			script += to_append
			script += "\n"
			is_empty = false

		if signal_node == null and entry_block.signal_name:
			signal_node = InstructionTree.TreeNode.new("{0}.connect(_on_{0})".format([entry_block.signal_name]))

	if signal_node:
		init_func.add_child(signal_node)

	if is_empty:
		script += "\tpass\n"

	return script


## Returns the scope of the first non-empty scope child block
static func get_tree_scope(node: Node) -> String:
	if node is Block:
		if node.scope != "":
			return node.scope

	for c in node.get_children():
		var scope := get_tree_scope(c)
		if scope != "":
			return scope
	return ""


## Get the nearest Block node that is a parent of the provided node.
static func get_parent_block(node: Node) -> Block:
	var parent = node.get_parent()
	while parent and not parent is Block:
		parent = parent.get_parent()
	return parent as Block
