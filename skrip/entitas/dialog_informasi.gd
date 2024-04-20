# 18/04/24
extends entitas

const jalur_instance = "res://skena/entitas/dialog_informasi.scn"
var sinkron_kondisi = [["properti_dialog", {}]]

@export var data_dialog : DialogueResource : 
	set(data):
		if data != null:
			properti_dialog = {
				"titles": data.titles,
				"first_title": data.first_title,
				"character_names": data.character_names,
				"lines": data.lines
			}
		data_dialog = data
var dialog : DialogueResource
var properti_dialog : Dictionary : 
	set(data):
		var tmp_dialog : DialogueResource = DialogueResource.new()
		tmp_dialog.titles = data["titles"]
		tmp_dialog.character_names = data["character_names"]
		tmp_dialog.first_title = data["first_title"]
		tmp_dialog.lines = data["lines"]
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
			server.permainan.tampilkan_dialog(dialog)
		else:
			Panku.notify("berkas dialog tidak tersedia")
