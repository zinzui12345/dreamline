extends Node3D

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

