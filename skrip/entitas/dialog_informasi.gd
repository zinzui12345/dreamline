# 18/04/24
extends entitas

const jalur_instance = "res://skena/entitas/dialog_informasi.scn"
var sinkron_kondisi = [["properti_dialog", {}]]

@export var data_dialog : DialogueResource : 
	set(data):
		if data != null:
			#print_debug(data.titles)
			#print_debug(data.first_title)
			#print_debug(data.character_names)
			#print_debug(data.lines)
			properti_dialog = {
				"titles": data.titles,
				"first_title": data.first_title,
				"character_names": data.character_names,
				"lines": data.lines
			}
		# debug : keknya mending pindah di setelah entitas di-instantiate() deh
		#server.permainan.dunia.print_tree_pretty()
		data_dialog = data
var dialog : DialogueResource
var properti_dialog : Dictionary : 
	set(data):
		var tmp_dialog : DialogueResource = DialogueResource.new()
		var indeks_baris = data.lines.keys()
		tmp_dialog.titles = data.titles
		tmp_dialog.character_names = data.character_names
		tmp_dialog.first_title = data.first_title
		# karena array kosong yang tersimpan di dictionary berformat default, atur format secara manual
		var tmp_arr_dict : Array[Dictionary] = []
		for baris in data.lines.size():
			if data.lines[indeks_baris[baris]].get("character_replacements") != null:
				if typeof(data.lines[indeks_baris[baris]]["character_replacements"]) == TYPE_ARRAY and data.lines[indeks_baris[baris]]["character_replacements"].size() == 0:
					data.lines[indeks_baris[baris]]["character_replacements"] = tmp_arr_dict
			if data.lines[indeks_baris[baris]].get("text_replacements") != null:
				if typeof(data.lines[indeks_baris[baris]]["text_replacements"]) == TYPE_ARRAY and data.lines[indeks_baris[baris]]["text_replacements"].size() == 0:
					data.lines[indeks_baris[baris]]["text_replacements"] = tmp_arr_dict
			if data.lines[indeks_baris[baris]].get("character") != null and data.lines[indeks_baris[baris]].get("character") != "" and !data.character_names.has(data.lines[indeks_baris[baris]].character):
				data.character_names.append(data.lines[indeks_baris[baris]].character)
		tmp_dialog.lines = data.lines
		dialog = tmp_dialog
		sinkron_kondisi[0][1] = data
		properti_dialog = data

func fokus():
	if not $AnimationPlayer.is_playing():
		$AnimationPlayer.play("fokus")
	server.permainan.set("tombol_aksi_2", "tanyakan_sesuatu")
func gunakan(id_pengguna):
	if id_pengguna == client.id_koneksi:
		if dialog != null:
			var id_dialog
			for _id_dialog in properti_dialog.titles:
				if properti_dialog.titles[_id_dialog] == properti_dialog.first_title:
					id_dialog = _id_dialog
			server.permainan.tampilkan_dialog(dialog, id_dialog)
		else:
			Panku.notify("berkas dialog tidak tersedia")
