extends OptionButton

func atur_tipe(tipe : String) -> void:
	match tipe:
		"bool":			select(0)
		"int":			select(1)
		"float":		select(2)
		"String":		select(3)
		"Array":		select(4)
		"Dictionary":	select(5)

func dapatkan_tipe() -> String:
	match selected:
		0:	return "bool"
		1:	return "int"
		2:	return "float"
		3:	return "String"
		4:	return "Array"
		5:	return "Dictionary"
		_: 	return "Variant"
