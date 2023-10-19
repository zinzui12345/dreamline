var _core:PankuConsole

const _HELP_bantuan := "Daftar variabel yang dilingkup." #List all environment variables.
var bantuan:String:
	get:
		var result = ["Objek terdaftar:\n"] #Registered objects
		var colors = ["#7c3f58", "#eb6b6f", "#f9a875", "#fff6d3"]
		var i = 0
		for k in _core.gd_exprenv._envs:
			var c = colors[i%4]
			i = i + 1
			result.push_back("[b][color=%s]%s[/color][/b]  "%[c, k])
		result.push_back("\n")
		result.push_back("Ketik [b]fungsi(objek)[/b] untuk mendapatkan informasi lebih lanjut.") #You can type [b]helpe(object)[/b] to get more information.
		return "".join(PackedStringArray(result))

const _HELP_fungsi := "Dapatkan informasi mengenai suatu variabel/fungsi tertentu" #Provide detailed information about one specific environment variable.
func fungsi(obj:Object) -> String:
	if !obj:
		return "tidak valid!" #Invalid!
	if !obj.get_script():
		return "Objek tidak memiliki script!" #It has no attached script!
	return PankuGDExprEnv.generate_help_text_from_script(obj.get_script())
