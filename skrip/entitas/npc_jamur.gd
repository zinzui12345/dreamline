# 11/11/23
extends npc_ai

# FIXME : optimalkan performa
# TODO : set parameter gestur ketika berjalan

enum varian_kondisi {
	diam,		# idle / keliling
	mengejar,	# menarget musuh / menyerang
	menghindar	# menjauh dari musuh
}

var musuh : Node3D
var kondisi = varian_kondisi.diam
var arah_pandangan = 0.0 :
	set(nilai):
		$model.rotation.y = nilai
		$fisik.rotation.y = nilai
		arah_pandangan = nilai

func setup():
	$model/Skeleton3D/Mushroom.visibility_range_end = jarak_render
	$model/AnimationTree.active = true
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		$pandangan.connect("body_entered", _ketika_melihat_sesuatu)
		$pandangan.monitoring = true
	else:
		$pandangan.queue_free()

func _process(delta):
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		if _proses_navigasi:
			$model.look_at(navigasi.get_next_path_position(), Vector3.UP, true)
			$model.rotation.x = 0
			arah_pandangan = $model.rotation.y
func _ketika_berjalan(arah):
	velocity = arah
	server.permainan.get_node("%nilai_debug").text = str(velocity.rotated(Vector3.UP, $model.rotation.y).normalized())
	move_and_slide()
	if server.permainan.koneksi == Permainan.MODE_KONEKSI.SERVER:
		var pmn = server.pemain.keys()
		for p in server.pemain.size():
			if server.cek_visibilitas_entitas_terhadap_pemain(server.pemain[pmn[p]]["id_client"], self.get_path(), jarak_render):
				server.atur_properti_objek(self.get_path(), "global_transform:origin", global_transform.origin)
				server.atur_properti_objek(self.get_path(), "arah_pandangan", arah_pandangan)
func _ketika_melihat_sesuatu(sesuatu : Node3D):
	if sesuatu is Karakter: _ketika_melihat_pemain(sesuatu)
func _ketika_melihat_pemain(pemain):
	Panku.notify("feel this love")
