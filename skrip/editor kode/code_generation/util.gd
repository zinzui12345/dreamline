extends Object


# karena optimasi DirAccess cuman bisa akses resource di Editor. untuk mengatasinya cek disini : https://forum.godotengine.org/t/any-way-to-pick-a-file-from-a-folder-in-the-project-at-random/71086/3
# HACK : pastiin nilai setelan editor/export/convert_text_resources_to_binary di set ke false
static func get_files_in_dir_recursive(path: String, pattern: String) -> Array:
	var files = []
	var dir := DirAccess.open(path)

	if not dir:
		return files

	dir.list_dir_begin()

	var file_name = dir.get_next()
	#print_debug("membuka direktori : "+path)
	
	while file_name != "":
		var file_path = path + "/" + file_name
		#print_debug("membuka file : "+file_path)
		if dir.current_is_dir():
			files.append_array(get_files_in_dir_recursive(file_path, pattern))
		elif file_name.matchn(pattern):
			files.append(file_path)

		file_name = dir.get_next()

	#print_debug("apakah file pada direktori ditemukan? : "+str(files != []))

	return files
