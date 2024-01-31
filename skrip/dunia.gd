extends Node3D

# Mulai modus server
func _ready():
	var argumen : Array = OS.get_cmdline_args() # ["res://skena/dreamline.tscn", "--server", "empty"]
	var jumlah_argumen  = argumen.size()
	for arg in jumlah_argumen:
		if argumen[arg] == "--server":
			server.publik = true
			if arg < jumlah_argumen - 2 and argumen[arg+1] != "" and argumen[arg+2] != "":
				server.permainan.atur_map(argumen[arg+1])
				server.permainan.buat_server(true, argumen[arg+2]);
				return
			elif arg < jumlah_argumen - 1 and argumen[arg+1] != "":
				server.permainan.atur_map(argumen[arg+1])
			server.permainan.buat_server(true);
			return

func hapus_map():
	if get_node_or_null("lingkungan") != null:
		get_node("lingkungan").queue_free()
	if $entitas.get_child_count() > 0:
		for entitas in $entitas.get_children():
			entitas.queue_free()
func hapus_instance_pemain():
	var jumlah_pemain = $pemain.get_child_count()
	for p in jumlah_pemain:
		#print_debug("menghapus pemain [%s/%s]" % [jumlah_pemain-p, jumlah_pemain])
		$pemain.get_child(jumlah_pemain - (p + 1)).queue_free()

